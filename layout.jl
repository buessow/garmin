using DataStructures
using LightXML

const DEVICE_ID = "fr265"

# doc = XML.read("devices.xml", XML.Node)

doc = LightXML.parse_file("devices.xml")

function children(el::XMLElement, n::String)
    return [c for c in LightXML.child_elements(el) if LightXML.name(c) == n]
end
function children(els::Vector{XMLElement}, n::String)
    return [c for el in els for c in LightXML.child_elements(el) if LightXML.name(c) == n]
end

OBSCURITIES = Dict(
    1 => "_Mid_L",
    3 => "_Top",
    4 => "_Mid_R",
    5 => "_Mid",
    6 => "_Top",
    7 => "_Top",
    9 => "_Bot_L",
    12 => "_Bot_R",
    13 => "_Bot",
    15 => "",
)

devices = children(children(root(doc), "devices")[1], "device")

l = Vector{Tuple{Vararg{Int, 5}}}()

for dev in devices
    device_id = attribute(dev, "id")
    if device_id != DEVICE_ID continue end
    println("dev $(attribute(dev, "id"))")
    i = 0
    field_count = 0

    for layout in children(children(dev, "datafieldlayouts")[1], "layout")
        fields = children(layout, "field")
        if length(fields) > field_count
            field_count = length(fields)
            i = 1
        else
            i += 1
        end
        for field in fields
            size = [parse(Int, attribute(field, n)) for n in["obscurity", "width", "height"]]
            push!(l, (size..., length(fields), i))
        end
    end
end

sort!(l)

fl = Vector{Tuple{Vector{Tuple{Int,Int,Int}}, Vector{Tuple{Int,Int}}}}()

co, cw, ch, f, v = l[1]
cs::Vector{Tuple{Int,Int,Int}} = [(cw, ch, co)]
fs = [(f, v)]

for (o, w, h, f, v) in l[2:end]
  if w in cw-2:cw+2 && h in ch-2:ch+2 && o == co
    push!(fs, (f, v))
    push!(cs, (w, h, o))
  else
    push!(fl, (cs, fs))
    global cw, ch, co, cs, fs = w, h, o, [(w, h, o)], [(f,v)]
  end
end
push!(fl, (cs, fs))

layout_names = Vector{String}()
for (cs, fvs) in fl
    ll = "L" * join(["$(f)$('A'+(v-1))" for (f, v) in SortedSet(fvs)], "_") * OBSCURITIES[cs[1][3]]
    push!(layout_names, ll)
    for (w, h, o) in cs
        println(""""L_$(w)x$(h)_$o": { "layout": "$ll" },<!-- XX -->""")
    end
end

println()

max_length = maximum(length.(layout_names))
for ln in sort(layout_names)
  println("   $(rpad("\"$ln\"", max_length+2)) => :$ln,")
end
