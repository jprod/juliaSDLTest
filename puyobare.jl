using Dates
using SimpleDirectMediaLayer
const SDL2 = SimpleDirectMediaLayer 

import SimpleDirectMediaLayer.LoadBMP

import Base.unsafe_convert
unsafe_convert(::Type{Ptr{SDL2.RWops}}, s::String) = SDL2.RWFromFile(s, "rb")

LoadBMP(src::String) = SDL2.LoadBMP_RW(src,Int32(1))

SCREEN_WIDTH  = 720
SCREEN_HEIGHT = 980

struct App
  window::Ptr{SDL2.Window}
  renderer::Ptr{SDL2.Renderer}
end

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

  if SDL2.Init(SDL2.INIT_VIDEO) < 0
    println("Couldn't initialize SDL: $(SDL2.GetError())")
    exit(1)
  end

  rendererFlags::UInt32 = SDL2.RENDERER_ACCELERATED
  windowFlags::UInt32 = SDL2.WINDOW_SHOWN

  win = SDL2.CreateWindow("Puyo", 
    Int32.((SDL2.WINDOWPOS_UNDEFINED_MASK, SDL2.WINDOWPOS_UNDEFINED_MASK, 
    SCREEN_WIDTH, SCREEN_HEIGHT))..., windowFlags)

  renderer = SDL2.CreateRenderer(win, Int32(-1), rendererFlags)

  SDL2.IMG_Init(Int32(SDL2.IMG_INIT_PNG | SDL2.IMG_INIT_JPG))

  return win, renderer
end

function doInput()
  ce = SDL2.CommonEvent(UInt32(1), floor(UInt32, datetime2unix(Dates.now())))
  event = Ptr{SDL2.WindowEvent}(pointer_from_objref(ce))
  while SDL2.PollEvent(event) != 0
    eventstar = unsafe_load(event)
    if eventstar._type == SDL2.QUIT
      exit(0)
      break
    else
      break
    end
  end  
end

function prepareScene(ren)
  SDL2.SetRenderDrawColor(ren, 96, 128, 255, 255)
  SDL2.RenderClear(ren)
end

function presentScene(ren)
  SDL2.RenderPresent(ren)
end

function loadTexture(ren, filename)
  println(SDL2.LOG_CATEGORY_APPLICATION, SDL2.LOG_PRIORITY_INFO, " Loading $filename")
  img = SDL2.IMG_Load(filename)
  tex = SDL2.CreateTextureFromSurface(ren, img)
  SDL2.FreeSurface(img)
  tex
end




win, ren = initSDL()

player = Entity(100, 100, loadTexture(ren, "./circ/circ.png"))

while true
  x,y = 500, 500

  prepareScene(ren)
  doInput()

  rect = SDL2.Rect(x,y,player.w,player.h)
  SDL2.RenderCopy(ren, player.texture, C_NULL, pointer_from_objref(rect))

  SDL2.RenderPresent(ren)

  SDL2.Delay(UInt32(16))
end
