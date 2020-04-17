local screen = component.proxy(component.list("screen")())
local gpu = component.proxy(component.list("gpu")())
local keeb = component.proxy(component.list("keyboard")())
screenX = 1 -- cursor pos
screenY = 1
screenW = 0
screenH = 0
function switch(t)
  t.case = function(self,x)
    local f = self[x] or self.default
    if f then
      if type(f) == "function" then
        f(x, self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

function moveforw()
  if screenX == screenW then screenX = 1; screenY = screenY + 1
  else screenX = screenX + 1 end
  if screenY == screenH + 1 then screenY = screenH end
end

function moveback()
  if screenX==1 then screenX = screenW; screenY = screenY - 1 
  else screenX = screenX - 1 end
  if screenY == 0 then screenY = 1 end
end

function clampcursor()
  if screenY == 0 then screenY = 1
  elseif screenY == screenH + 1 then screenY = screenH end
  if screenX == 0 then screenX = 1
  elseif screenX == screenW + 1 then screenX = screenW end
end

esccodeparse = switch {
  ['\a'] = function (x) computer.beep() end,
  ['\b'] = function (x) moveback(); gpu.set(screenX, screenY, " ") end,
  ['\f'] = function (x) gpu.fill(1, 1, screenW, screenH, " "); screenX, screenY = 1, 1 end,
  ['\n'] = function (x) screenX = 1; screenY = screenY + 1; clampcursor() end,
  ['\r'] = function (x) screenX = 1 end,
  ['\t'] = function (x) moveforw(); moveforw() end,
  ['\v'] = function (x) screenY = screenY + 2; clampcursor() end,
  default = function (x) gpu.set(screenX, screenY, x); moveforw() end,
}

function os.sleep(timeout)
  checkArg(1, timeout, "number", "nil")
  local deadline = computer.uptime() + (timeout or 0)
  repeat
    computer.pullSignal(deadline - computer.uptime())
  until computer.uptime() >= deadline
end

function print(out)
  for c in string.gmatch(tostring(out), ".") do
    esccodeparse:case(c)
  end
end

local libvfs = {
  created = {},
  create = function (self)
    addr = math.random()
    while self.created[addr] ~= nil do addr = math.random() end
    self.created[addr] = {}
    return addr
  end,
  mount = function (self, vfsaddr, mountaddr, mountpoint, notanfs)
    if self.created[vfsaddr] == nil then return nil end
    if mountaddr == nil then return nil end
    if mountpoint == nil then return nil end
    if component.proxy(mountaddr).spaceUsed() == nil and not notanfs then return nil end --check if its an fs
    self.created[vfsaddr][mountpoint] = mountaddr
    return true
  end,
}

function panic (errormsg)
  print("\n\apanic!!!: \a")
  print(errormsg.."\a\n\a")
  debug.traceback()
  while 1 do os.sleep(9999) end
end

do -- setup
  if not gpu.bind(screen.address) then
    error("Failed to bind to screen")
  end
  screenW, screenH = gpu.getResolution()
  if gpu.getDepth() == 1 then gpu.setBackground(0x0); gpu.setForeground(0x1)
  else gpu.setBackground(0x222222); gpu.setForeground(0xaaaaaa) end
  os.sleep(0.3)
  print("\f\a Booting TOC/OS...\n")
  _G._OSVERSION = "TOC/OS"
  os.sleep(0.5)
  local totalram = computer.totalMemory()
  local gpumaxdepth = math.floor(gpu.maxDepth())
  local gpucurdepth = math.floor(gpu.getDepth())
  local freeram = computer.freeMemory()
  print(" "..tostring(totalram).." byte RAM system; "..tostring(freeram).." bytes free.\n Maximum color depth: "..tostring(gpumaxdepth).."; Current color depth: "..tostring(gpucurdepth)..".\n")
  print("\t- Loading the VFS... ")
  local progressbar1x, progressbar1y = screenX, screenY
  print("\n\t\t- Creating the VFS... ")
  local vfs = libvfs:create()
  if vfs == nil then print("FAILED"); panic("failed to make vfs!") end
  print("OK!\n")
  print("\t\t- Mounting boot disk... ")
  if not libvfs:mount(vfs, computer.getBootAddress(), "/") then print("FAILED"); panic("failed to mount boot disk!") end
  print("OK!\n")
  print("\t\t- Mounting tmpfs... ")
  if not libvfs:mount(vfs, computer.tmpAddress(), "/tmp") then print("FAILED"); panic("failed to mount tmpfs!") end
  print("OK!\n")
  print("\t\t- Loading devfs... ")
  local progressbar2x, progressbar2y = screenX, screenY
  print("\n\t\t\t- Creating devfs... ")
  local devfs = libvfs:create()
  if devfs == nil then print("FAILED"); panic("failed to make devfs!") end
  print("OK!\n")
end
while 1 do -- main
  os.sleep(0.5)
end
