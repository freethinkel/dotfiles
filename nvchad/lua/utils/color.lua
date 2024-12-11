local HEX_DIGITS = {
  ["0"] = 0,
  ["1"] = 1,
  ["2"] = 2,
  ["3"] = 3,
  ["4"] = 4,
  ["5"] = 5,
  ["6"] = 6,
  ["7"] = 7,
  ["8"] = 8,
  ["9"] = 9,
  ["a"] = 10,
  ["b"] = 11,
  ["c"] = 12,
  ["d"] = 13,
  ["e"] = 14,
  ["f"] = 15,
  ["A"] = 10,
  ["B"] = 11,
  ["C"] = 12,
  ["D"] = 13,
  ["E"] = 14,
  ["F"] = 15,
}

local Color = {}

local _mixColorChannel = function(channelA, channelB, amount)
  return (channelA * amount) + (channelB * (1 - amount))
end

local tohex = function(num)
  local val = string.format("%x", num)
  if string.len(val) == 2 then
    return val
  end

  return "0" .. val
end

local hex_to_rgb = function(hex)
  hex = string.sub(hex, 2, 7)
  return {
    HEX_DIGITS[string.sub(hex, 1, 1)] * 16 + HEX_DIGITS[string.sub(hex, 2, 2)],
    HEX_DIGITS[string.sub(hex, 3, 3)] * 16 + HEX_DIGITS[string.sub(hex, 4, 4)],
    HEX_DIGITS[string.sub(hex, 5, 5)] * 16 + HEX_DIGITS[string.sub(hex, 6, 6)],
  }
end

Color.lerp = function(colorA, colorB, amount)
  colorA = hex_to_rgb(colorA)
  colorB = hex_to_rgb(colorB)
  amount = 1 - amount
  local mixed = {
    _mixColorChannel(colorA[1], colorB[1], amount),
    _mixColorChannel(colorA[2], colorB[2], amount),
    _mixColorChannel(colorA[3], colorB[3], amount),
  }

  return "#" .. tohex(mixed[1]) .. tohex(mixed[2]) .. tohex(mixed[3])
end

return Color
