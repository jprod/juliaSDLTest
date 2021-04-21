using Match
using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import Base.unsafe_convert
unsafe_convert(::Type{Ptr{SDL2.RWops}}, s::String) = SDL2.RWFromFile(s, "rb")

LoadBMP(src::String) = SDL2.LoadBMP_RW(src,Int32(1))

SCREEN_WIDTH  = 720
SCREEN_HEIGHT = 980

struct Entity
  x::Int
  y::Int
  w::Int
  h::Int
  texture::Ptr{SDL2.Texture}
  Entity(x, y, texture) = begin fx,fy = Int[1], Int[1]
    SDL2.QueryTexture(texture, C_NULL, C_NULL, pointer(fx), pointer(fy))
    fx,fy = fx[1],fy[1]
    new(x, y, fx, fy, texture)
  end
end

mutable struct Filler end

function initSDL()
  SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLEBUFFERS, 16)
  SDL2.GL_SetAttribute(SDL2.GL_MULTISAMPLESAMPLES, 16)

  SDL2.init()

  rendererFlags::UInt32 = SDL2.RENDERER_ACCELERATED
  windowFlags::UInt32 = SDL2.WINDOW_SHOWN


  sdlwin = SDL2.SDLWindow(SCREEN_WIDTH,SCREEN_HEIGHT,"Puyo!")

  SDL2.IMG_Init(Int32(SDL2.IMG_INIT_PNG | SDL2.IMG_INIT_JPG))

  return sdlwin
end

function doInput(sdlwin, gs)
  while (event = SDL2.event(); event) != nothing
    # println(event)
    # println(event._type)
    @match event._type begin
        SDL2.QUIT => exit(1)
        SDL2.KEYDOWN => handleKey(event, gs)
        SDL2.WINDOWEVENT => handleWin(event, gs, sdlwin)
    end
  end
end

function handleKey(event, gs)
  println("handling key")
  println(event.keysym.sym)
  @match event.keysym.sym begin
    SDL2.SDLK_LEFT => (gs["rcSrcx"] = 192; gs["rcSpritex"] = get(gs, "rcSpritex", 500) - 5)
  end
  println(gs)
end

function handleWin(event, gs, sdlwin)
  println("handling window event")
  println(event.event)
  @match event.event begin
    SDL2.WINDOWEVENT_RESIZED => begin 
      w,h = Int32[-1],Int32[-1]
      SDL2.GetWindowSize(sdlwin.win, w,h)
      gs["winwidth"] = w[]
      gs["winheight"] = h[]
      end
  end
  println(gs)
end

function loadTexture(ren, filename)
  println(SDL2.LOG_CATEGORY_APPLICATION, SDL2.LOG_PRIORITY_INFO, " Loading $filename")
  img = SDL2.IMG_Load(filename)
  tex = SDL2.CreateTextureFromSurface(ren, img)
  SDL2.FreeSurface(img)
  tex
end



function main()  
  sdlwin = initSDL()

  player = Entity(100, 100, loadTexture(sdlwin.renderer, "./circ/circ.png"))

  gs = Dict("winwidth" => SCREEN_WIDTH, "winheight" => SCREEN_HEIGHT)
  tick = 0

  while true
    x,y = (500 + 5*tick) % gs["winwidth"], (500 + 20*tick) % gs["winheight"]
    SDL2.SetRenderDrawColor(sdlwin.renderer, 96, 128, 255, 255)
    SDL2.RenderClear(sdlwin.renderer)

    doInput(sdlwin, gs)

    rect = SDL2.Rect(x,y,player.w,player.h)
    SDL2.RenderCopy(sdlwin.renderer, player.texture, C_NULL, pointer_from_objref(rect))

    SDL2.RenderPresent(sdlwin.renderer)

    tick += 1
    # SDL2.Delay(UInt32(1))
  end
end

main()
