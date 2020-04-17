local screen = component.proxy(component.list("screen")())
local gpu = component.proxy(component.list("gpu")())
local keeb = component.proxy(component.list("keyboard")())
local fs = nil
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

end
while 1 do -- main
  os.sleep(0.5)
end