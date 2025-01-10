local lvgl = require("lvgl")
local dataman = require("dataman")
local lunajson = require ('lunajson')

require "image"
require "root"

local DW = 192
local DH = 490
local T_WIDTH = 50
local T_HEIGHT = 94
local T_SPACE = 10
local oldtimeValue = 0
--local indexGraph = 0

local dateline = (DH/2)+T_HEIGHT+(T_SPACE/2)+12
local GRAPH_SETTINGS = { x=5, y=165, w=184, h=125, point_size=6, treatment_point_size=9, line_size=2 }

local arrowTrendPosition= { 157+5, 283 }

local textLog=""

local function log(watchface,texto)
    if textLog=="" then
        textLog=texto
    else
        textLog=string.format("%s\n%s",textLog,texto)
    end
    watchface.labelLog:set { text =  textLog}
end

local function getItemsTimePosition()

    local imgTimePosition = {
        timeHourHigh =		{ 13, 140 },
        timeHourLow =		{ 51, 140 },
        timeDelim =		    { 89, 140 },
        timeMinuteHigh =	{ 103, 140 },
        timeMinuteLow =		{ 141, 140 },
        timeSecondHigh =	{ 30, dateline },
        timeSecondLow =		{ 43, dateline },
    }

    return imgTimePosition
end

local function getItemsDatePosition()

    local imgDatePosition = {
        dateWeek =		{ 62, dateline },
        dateDayHigh =		{ 109, dateline },
        dateDayLow =		{ 122, dateline },
        dateDelim =		    { 135, dateline },
        dateMonthHigh =	    { 148, dateline },
        dateMonthLow =		{ 161, dateline },
    }

    return imgDatePosition
end

local function getItemsBGPosition()

	local imgBGPosition = {
        bgXY =		{ 2, 285 }, --32 
        bgWidth = 113, --125 
        bgHeight = 60,
    }
    return imgBGPosition
end

local function getItemsDeltaPosition()

    local imgDeltaPosition = {
        deltaXY =		{ 100, 285 },
    }
    return imgDeltaPosition
end

local function getItemsTimeBGPosition()

    local imgTimeBGPosition = {
        timeXY =		{ 110, 317 },
    }
    return imgTimeBGPosition
end

local function getItemsHeartPosition()

    local imgHeartPosition = {
        heartXY =		{ 71, 442},
    }
    return imgHeartPosition
end

local function getItemsWeatherPosition()

    local imgWeatherPosition = {
        weaXY =		{ 66, 70+10 },
    }
    return imgWeatherPosition
end

local function getTimeStr(timeValue)

    local t =  os.time() - (timeValue/1000)
    local unit = 'a' --sec
    if t ~= 1 then
        unit = 'a'
    end
    if t > 59 then
        unit = 'b' --min
        t = t / 60
        if t ~= 1 then
            unit = 'c' --mins
        end
        if t > 59  then
            unit = 'j' --hour
            t = t / 60
            if t ~= 1 then
                unit = 'e' --hours
            end
            if t > 24 then
                unit = 'f' --day
                t = t / 24
                if t ~= 1 then
                    unit = 'g' --days
                end
                if t > 28 then
                    unit = 'h' --week
                    t = t / 7
                    if t ~= 1 then
                        unit = 'i' --weeks
                    end 
                end
            end
        end
    else
        return "x" --now
    end
    return string.format("%d%s",math.floor(t),unit)
end

local function findString(texto,patron)
    local iterator=1
    while iterator<=string.len(texto) do
        local caracter=string.sub(texto,iterator,iterator)
        if patron==caracter then
            return iterator
        else
            iterator=iterator+1
        end
    end
    return 0
end

local function paintTextObjectLeft(watchface,objeto,ruta,x, y, width,texto)
    local iterator=1
    while iterator<=#objeto do
        objeto[iterator].widget:add_flag(lvgl.FLAG.HIDDEN)
        iterator=iterator+1
    end

    iterator=1
    while iterator<=string.len(texto) do
        local caracter=string.sub(texto,iterator,iterator)
        local src = string.format(ruta, caracter)
        objeto[iterator].widget:set { src = imgPath(src) }
        objeto[iterator].widget:clear_flag(lvgl.FLAG.HIDDEN)
        iterator=iterator+1
    end
end

local function paintTextObjectRight(watchface,objeto,ruta,x, y, width,texto)
    local iterator=1
    while iterator<=#objeto do
        objeto[iterator].widget:add_flag(lvgl.FLAG.HIDDEN)
        iterator=iterator+1
    end

    local diferencia=#objeto-string.len(texto)
    iterator=string.len(texto)
    while iterator>0 do
        local caracter=string.sub(texto,iterator,iterator)
        local src = string.format(ruta, caracter)
        objeto[iterator+diferencia].widget:set { src = imgPath(src) }
        objeto[iterator+diferencia].widget:clear_flag(lvgl.FLAG.HIDDEN)
        iterator=iterator-1
    end
end

local function paintTextObject(watchface,objeto,ruta,x,y,width,widthSeparador,separador,posSeparador,texto)

    local diferencia=#objeto-string.len(texto)
    local iterator=1
    while iterator<=#objeto do
        objeto[iterator].widget:add_flag(lvgl.FLAG.HIDDEN)
        iterator=iterator+1
    end

    iterator=1
    if string.len(separador)>0 and findString(texto,separador)>0 then
        iterator=iterator+diferencia
    end 
    local iteratorTxt=1
    while iteratorTxt<=string.len(texto) do
        local xOffset=0
        if string.len(separador)==0 or (string.len(separador)>0 and findString(texto,separador)==0) then
            if string.len(separador)==0 then
                xOffset=(diferencia*width/2)+((iteratorTxt-1)*width)
            else
                xOffset=(((diferencia-1)*width)/2)+(widthSeparador/2)+((iteratorTxt-1)*width)
            end
        else
            if findString(texto,separador)<iteratorTxt then
                xOffset=((diferencia*width)/2)+((iteratorTxt-2)*width)+(widthSeparador)
            else
                xOffset=((diferencia*width)/2)+((iteratorTxt-1)*width)
            end
        end
        local caracter=string.sub(texto,iteratorTxt,iteratorTxt)
        if string.len(separador)>0 and (iterator==posSeparador and caracter~=separador) then
            iterator=iterator+1
        elseif caracter=="x" or caracter=="a" or  caracter=="b" or caracter=="c" or caracter=="f" or caracter=="g" or caracter=="h" or caracter=="i" or caracter=="j" or caracter=="e" then
            iterator=3
        end
        if caracter=="." then
            caracter="d"
        elseif caracter=="+" then
            caracter="plus"
        elseif caracter=="-" then
            caracter="minus"
        elseif caracter=="w" then
            ruta="images/weather_numbers/%s.png"
            caracter="degree"
        end
        local src = string.format(ruta, caracter)
        objeto[iterator].widget:set { src = imgPath(src) }
        objeto[iterator].pos.x = x + xOffset
        objeto[iterator].widget:set { x = objeto[iterator].pos.x }
        objeto[iterator].widget:clear_flag(lvgl.FLAG.HIDDEN)

        iteratorTxt=iteratorTxt+1
        iterator=iterator+1
    end
end

local function clearGraph(watchface)
    if watchface.graph.widgets~=nil then
        local iterator=#watchface.graph.widgets
        while iterator>=1 do
            local punto=watchface.graph.widgets[iterator]
            punto:add_flag(lvgl.FLAG.HIDDEN)
            table.remove(watchface.graph.widgets,iterator)
            iterator=iterator-1
        end
        watchface.graphObject:clean()
    end
end

local Colors = {
    default = '#fc6950',
    defaultTransparent = '#ababab',
    white = '#ffffff',
    black = '#000000',
    bgHigh = '#ffa0a0',
    bgLow = '#8bbbff',
    accent = '#ffbeff37',
}

local function createGraph(watchface)
    local property = {
        x= 0,
        y= 0,
        w = 192,
        h = 490,
        bg_color = 0,
        bg_opa = lvgl.OPA(100),
        border_width = 0,
        pad_all = 0
    }

    local scr = lvgl.Object(watchface.padre, property)
    scr:clear_flag(lvgl.FLAG.SCROLLABLE)
    scr:add_flag(lvgl.FLAG.EVENT_BUBBLE)
    return scr
end


local function createWidget(watchface, x, y, pointStyle)
    local property = {
        x = x,
        y = y,
        w = pointStyle.width,
        h = pointStyle.height,
        radius = pointStyle.radius,
        color = pointStyle.color,
        bg_opa = lvgl.OPA(100),
        bg_color = pointStyle.color,
        border_width = 0,
        pad_all = 0,
    }

    local widget = lvgl.Object(watchface.graphObject, property)
    --indexGraph=#watchface.padre
    widget:clear_flag(lvgl.FLAG.SCROLLABLE)
    if widget~=nil and watchface.graph~=nil and watchface.graph.widgets~=nil then
        table.insert(watchface.graph.widgets, widget)
    end
end

local function drawPoint(watchface, x, y, pointStyle)
    if x < watchface.graph.x or x > watchface.graph.xBound then
        return
    end
    if y < watchface.graph.y or y > watchface.graph.yBound then
        return
    end
    createWidget(watchface, x, y, pointStyle)
end

local function drawLine(watchface, x, y, pointStyle)

    --log(watchface,string.format("Leida linea1 %s %s %d %d", type(pointStyle.width), type(pointStyle.height),pointStyle.width,pointStyle.height))
    if y < watchface.graph.y or y > watchface.graph.yBound then
        return
    end
    pointStyle.width = watchface.graph.width
    --log(watchface,string.format("Leida linea2 %s %s %d %d", type(pointStyle.width), type(pointStyle.height),pointStyle.width,pointStyle.height))
    createWidget(watchface.graph, x, y, pointStyle)
end

local function drawElement(watchface, x, y, pointStyle, lineName)
    local xPos = watchface.graph.x + x - (pointStyle.width / 2);
    local yPos = watchface.graph.y + watchface.graph.height - y - (pointStyle.height / 2);
    if string.find(lineName,"line")==nil then
        drawPoint(watchface,xPos, yPos, pointStyle)
    else
        drawLine(watchface,xPos, yPos, pointStyle)
    end
end

local function draw(watchface)
    --log(watchface,"Entro en draw")   
    if watchface.graph.lines == nil  then
        return
    end
    --log(watchface,"draw limpiamos grafico")   

    clearGraph(watchface)
    --log(watchface,"draw grafico limpiado")   

    if watchface.graph.viewport == nil then
        return
    end
    --log(watchface,"draw hay viewPort")

    local viewportWidth = watchface.graph.viewport.right - watchface.graph.viewport.left;
    local viewportHeight = watchface.graph.viewport.top - watchface.graph.viewport.bottom;
    --log(watchface,"draw viewPort correcto")   
    local iterator1=1

    --log(watchface,string.format("draw tam lineas %d",#watchface.graph.lines))

    while iterator1<=#watchface.graph.lines do
        local line=watchface.graph.lines[iterator1]
        --log(watchface,string.format("draw linea %s %s", line.name, type(line.pointStyle)))

        --log(watchface,string.format("trato linea %d %s",iterator1,line.name))
        local iterator2=1
        --log(watchface,string.format("draw Num Puntos %d",#line.points))
        while iterator2<=#line.points do
            local point=line.points[iterator2]
            local time = tonumber(point[1])
            local val = tonumber(point[2])
            local diffx = time - watchface.graph.viewport.left
            local x = (diffx * tonumber(watchface.graph.width)) / tonumber(viewportWidth)
            local diffy = val - watchface.graph.viewport.bottom
            local y = (diffy * tonumber(watchface.graph.height)) / tonumber(viewportHeight)
            --log(watchface,string.format("X %s",type(x)))
            --log(watchface,string.format("Y %d",y))
            --log(watchface,string.format("line %s",line.name))

            drawElement(watchface, x, y, line.pointStyle, line.name)
            iterator2=iterator2+1
        end
        iterator1=iterator1+1
    end
end



local MMOLL_TO_MGDL = 18.0182
local GRAPH_LIMIT = 18


local function paintGraph(watchface,watchdripData)
--    log(watchface,"Entro en paintGraph")
--    watchface.bg[1].widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.bg[2].widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.bg[3].widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.bg[4].widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.timeHourHigh.widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.timeHourLow.widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.timeMinuteHigh.widget:add_flag(lvgl.FLAG.HIDDEN)
--    watchface.timeMinuteLow.widget:add_flag(lvgl.FLAG.HIDDEN)

    if watchface.graph ~= nil then
        clearGraph(watchface)
    else
        watchface.graph={}
        watchface.graph.x = GRAPH_SETTINGS.x;
        watchface.graph.y = GRAPH_SETTINGS.y;
        watchface.graph.height = GRAPH_SETTINGS.h;
        watchface.graph.width = GRAPH_SETTINGS.w;
        watchface.graph.xBound = GRAPH_SETTINGS.x + GRAPH_SETTINGS.w;
        watchface.graph.yBound = GRAPH_SETTINGS.y + GRAPH_SETTINGS.h;
        watchface.graph.widgets={}
    end
--    log(watchface,"paintGraph Comienzo la creacion")

    watchface.graph.graphLineStyles= {}
    local POINT_SIZE = GRAPH_SETTINGS.point_size
    local TREATMENT_POINT_SIZE = GRAPH_SETTINGS.treatment_point_size
    local LINE_SIZE = GRAPH_SETTINGS.line_size

    watchface.graph.graphLineStyles['predict'] = {width=POINT_SIZE, height=POINT_SIZE, radius=POINT_SIZE,imageFile="",color = ""}
    watchface.graph.graphLineStyles['high'] = {width=POINT_SIZE, height=POINT_SIZE, radius=POINT_SIZE, imageFile="",color = ""}
    watchface.graph.graphLineStyles['low'] = {width=POINT_SIZE, height=POINT_SIZE, radius=POINT_SIZE, imageFile="",color = ""}
    watchface.graph.graphLineStyles['inRange'] = {width=POINT_SIZE, height=POINT_SIZE, radius=POINT_SIZE, imageFile="",color = ""}
    watchface.graph.graphLineStyles['lineLow'] = {width=0, height=LINE_SIZE, radius=0, imageFile="",color = ""}
    watchface.graph.graphLineStyles['lineHigh'] = {width=0, height=LINE_SIZE, radius=0, imageFile="",color = ""};
--    log(watchface,"paintGraph Creados formatos de Linea")

    if (watchdripData["graph"]["start"]==nil) then
        return
    end
--    log(watchface,"paintGraph Hay datos de grafica")

    local isMgdl=watchdripData["status"]["isMgdl"]

    local viewportTop = GRAPH_LIMIT
    if isMgdl then
        viewportTop= GRAPH_LIMIT * MMOLL_TO_MGDL
    end

    watchface.graph.viewport = {left=tonumber(watchdripData["graph"]["start"]), right=tonumber(watchdripData["graph"]["end"]), bottom=0, top=viewportTop}
--    log(watchface,"paintGraph Creado viewPort")
    
    local iterator=1
    watchface.graph.lines={}
    while iterator<=#watchdripData["graph"]["lines"] do
        local line=watchdripData["graph"]["lines"][iterator]
        local name = line["name"]
        local lineStyle = watchface.graph.graphLineStyles[name]

        if (lineStyle==nil) then
            lineStyle = {width=POINT_SIZE, height=POINT_SIZE, radius=POINT_SIZE,imageFile="",color = ""}
        end

        if (lineStyle.color == nil or lineStyle.color=="")  then
            lineStyle.color = line["color"]
        end
        local lineObj = {}
        lineObj.name = name
        lineObj.pointStyle = lineStyle
        lineObj.points = line["points"]
        --log(watchface,string.format("Color1 %s %s", type(lineObj.pointStyle.color), lineObj.pointStyle.color))

        lineObj.pointStyle.color=string.lower(string.gsub(lineObj.pointStyle.color,"0x","#"))
        --log(watchface,string.format("Color2 %s %s", type(lineObj.pointStyle.color),lineObj.pointStyle.color))
        --watchface.graph.lines[name] = lineObj;
        table.insert(watchface.graph.lines, lineObj)
        --log(watchface,string.format("paintGraph Creada linea %s %s", name, type(lineObj.pointStyle)))
        --log(watchface,string.format("paintGraph Leida linea %s %s %s %s %s %s", watchface.graph.lines[iterator].name, type(watchface.graph.lines[iterator].pointStyle),type(watchface.graph.lines[iterator].pointStyle.width), type(watchface.graph.lines[iterator].pointStyle.height), type(watchface.graph.lines[iterator].pointStyle.radius),type(watchface.graph.lines[iterator].pointStyle.color)))
        iterator=iterator+1
        --log(watchface,string.format("paintGraph Num puntos %d",#lineObj.points))
    end
--    log(watchface,"paintGraph Creadas lineas")

    draw(watchface)
end



local function updateBGValue(watchface)

    local file=io.open("//data/quickapp/files/com.thatguysservice.huami_xdrip/info.json","r");
    if file then
        local g=1
    else
        file=io.open("//data/quickapp/files/com.application.watch.watchdrip/info.json","r");
    end

    if file then
        local content = file:read("*all")
        file:close()
        local t = lunajson.decode(content)

        local timeValue = t["bg"]["time"]
        local textTime=getTimeStr(timeValue)
        local posTime=getItemsTimeBGPosition();
        paintTextObject(watchface,watchface.timeBG,"images/numTimeBG/%s.png",posTime.timeXY[1],posTime.timeXY[2],19,0,"",0,textTime)
        if timeValue == oldtimeValue then
            return;
        end
        oldtimeValue=timeValue

        local bgValue=t["bg"]["val"]
        local isMgdl=t["status"]["isMgdl"]
        local phoneBat=t["status"]["bat"]
        local isHigh=t["bg"]["isHigh"]
        local isLow=t["bg"]["isLow"]
        local trend=t["bg"]["trend"]

        local src = string.format("images/arrows/%s.png", trend)
        watchface.arrowTrend.widget:set { src = imgPath(src) }

        local delta = t["bg"]["delta"]
        local posDelta=getItemsDeltaPosition();
        paintTextObject(watchface,watchface.delta,"images/numDelta/%s.png",posDelta.deltaXY[1],posDelta.deltaXY[2],16,7,".",4,delta)

        local posBG = getItemsBGPosition();

        if isHigh then
            paintTextObject(watchface,watchface.bg,"images/bgNumHigh/%s.png",posBG.bgXY[1],posBG.bgXY[2],32,17,".",3,bgValue)
        elseif isLow then
            paintTextObject(watchface,watchface.bg,"images/bgNumLow/%s.png",posBG.bgXY[1],posBG.bgXY[2],32,17,".",3,bgValue)
        else
            paintTextObject(watchface,watchface.bg,"images/bgNum/%s.png",posBG.bgXY[1],posBG.bgXY[2],32,17,".",3,bgValue)
        end

        --paintTextObject(watchface,watchface.delta,"images/numDelta/%s.png",posDelta.deltaXY[1],posDelta.deltaXY[2],18,7,".",4,delta)

        local valor=phoneBat;
        local arc=math.floor(valor*0.17)
        if arc>17 then
            arc=17
        end
        local srcArc = string.format("images/arcs/blue%d.png", arc)
        watchface.phoneBatteryArc.widget:set { src = imgPath(srcArc) }
        local valueText = string.format("%d", math.floor(valor))

        paintTextObjectLeft(watchface,watchface.phoneBatteryValue,"images/status_numbig/%s.png",37,490-104, 14,valueText)

        paintGraph(watchface,t)
    else
        watchface.bg[1].widget:add_flag(lvgl.FLAG.HIDDEN)
        watchface.bg[2].widget:add_flag(lvgl.FLAG.HIDDEN)
        watchface.bg[3].widget:add_flag(lvgl.FLAG.HIDDEN)
        watchface.bg[4].widget:add_flag(lvgl.FLAG.HIDDEN)
        watchface.arrowTrend.widget:add_flag(lvgl.FLAG.HIDDEN)
    end
end

local function entry()

    local root = createRoot()

	local watchface = {}

	local posTime = getItemsTimePosition();

    watchface.padre=root
    local graph=createGraph(watchface)
    watchface.graphObject=graph

    watchface.labelLog = root:Label{
        x=0, y=120, w=192, h=100,
        text_font = lvgl.BUILTIN_FONT.MONTSERRAT_28,
        text = "",
        bg_color = 0,
        border_color='#eeeeee',
        border_width = 0,
        text_color = '#eeeeee'
    }

    watchface.timeHourHigh =	Image(root, "images/time_numbers/0.png", posTime.timeHourHigh)
    watchface.timeHourLow =		Image(root, "images/time_numbers/0.png", posTime.timeHourLow)
    watchface.timeDelim =       Image(root, "images/time_numbers/sp.png", posTime.timeDelim)
    watchface.timeMinuteHigh =	Image(root, "images/time_numbers/0.png", posTime.timeMinuteHigh)
    watchface.timeMinuteLow =	Image(root, "images/time_numbers/0.png", posTime.timeMinuteLow)
    watchface.timeSecondHigh =	Image(root, "images/status_numbers/0.png", posTime.timeSecondHigh)
    watchface.timeSecondLow =	Image(root, "images/status_numbers/0.png", posTime.timeSecondLow)

    local posDate=getItemsDatePosition()
    watchface.dateWeek =	Image(root, "images/days/1.png", posDate.dateWeek)
    watchface.dateDayHigh =	Image(root, "images/status_numbers/0.png", posDate.dateDayHigh)
    watchface.dateDayLow =		Image(root, "images/status_numbers/0.png", posDate.dateDayLow)
    watchface.dateDelim =       Image(root, "images/status_numbers/slash.png", posDate.dateDelim)
    watchface.dateMonthHigh =	Image(root, "images/status_numbers/0.png", posDate.dateMonthHigh)
    watchface.dateMonthLow =	Image(root, "images/status_numbers/0.png", posDate.dateMonthLow)


    dataman.subscribe("timeHourHigh", watchface.timeHourHigh.widget, function(obj, value)
        local src = string.format("images/time_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("timeHourLow", watchface.timeHourLow.widget, function(obj, value)
        local src = string.format("images/time_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("timeMinuteHigh", watchface.timeMinuteHigh.widget, function(obj, value)
        local src = string.format("images/time_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("timeMinuteLow", watchface.timeMinuteLow.widget, function(obj, value)
        local src = string.format("images/time_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("timeSecondHigh", watchface.timeSecondHigh.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("timeSecondLow", watchface.timeSecondLow.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    -- handle demiliter blinking
    dataman.subscribe("timeSecondLow", watchface.timeDelim.widget, function(obj, value)
        local second = value // 256
        second = second & 0x01 -- take a low bit of second, odd/even
        if second == 0 then
            obj:clear_flag(lvgl.FLAG.HIDDEN)
            updateBGValue(watchface);
        else
            obj:add_flag(lvgl.FLAG.HIDDEN)
        end
    end)


    dataman.subscribe("dateWeek", watchface.dateWeek.widget, function(obj, value)
        local src = string.format("images/days/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("dateDayHigh", watchface.dateDayHigh.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("dateDayLow", watchface.dateDayLow.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("dateMonthHigh", watchface.dateMonthHigh.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    dataman.subscribe("dateMonthLow", watchface.dateMonthLow.widget, function(obj, value)
        local src = string.format("images/status_numbers/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    local posWeather = getItemsWeatherPosition();
    watchface.weatherIcon =Image(root, "images/weather/3.png", {76, 25+10})
    dataman.subscribe("weatherCurrentWeather", watchface.weatherIcon.widget, function(obj, value)
        local src = string.format("images/weather/%d.png", value // 256)
        obj:set { src = imgPath(src) }
    end)

    watchface.weatherValue = {Image(root, "images/weather_numbers/minus.png", { posWeather.weaXY[1], posWeather.weaXY[2] }),Image(root, "images/weather_numbers/0.png", { posWeather.weaXY[1]+17, posWeather.weaXY[2] }),Image(root, "images/weather_numbers/0.png", { posWeather.weaXY[1]+34, posWeather.weaXY[2] }),Image(root, "images/weather_numbers/degree.png", { posWeather.weaXY[1]+51, posWeather.weaXY[2] })}
    dataman.subscribe("weatherCurrentTemperature", watchface.weatherIcon.widget, function(obj, value)
        local valueText = string.format("%dw", value // 256)
        paintTextObject(watchface,watchface.weatherValue,"images/weather_numbers/%s.png",posWeather.weaXY[1], posWeather.weaXY[2],17,0,"",0,valueText)
    end)

	local posHeart = getItemsHeartPosition();
    watchface.heartIcon=Image(root, "images/icons_l/heart.png", {81, 405})
    watchface.heartValue = {Image(root, "images/weather_numbers/0.png", { posHeart.heartXY[1], posHeart.heartXY[2] }),Image(root, "images/weather_numbers/0.png", { posHeart.heartXY[1]+17, posHeart.heartXY[2] }),Image(root, "images/weather_numbers/0.png", { posHeart.heartXY[1]+34, posHeart.heartXY[2] })}

    dataman.subscribe("healthHeartRate", watchface.heartIcon.widget, function(obj, value)
        local valueText = string.format("%d", value // 256)
        if (value // 256)>400 then
            watchface.heartValue[1].widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.heartValue[2].widget:add_flag(lvgl.FLAG.HIDDEN)
            watchface.heartValue[3].widget:add_flag(lvgl.FLAG.HIDDEN)
        else
            paintTextObject(watchface,watchface.heartValue,"images/weather_numbers/%s.png",posHeart.heartXY[1], posHeart.heartXY[2],17,0,"",0,valueText)
        end
    end)

    local posBG = getItemsBGPosition();
    watchface.bg = {Image(root, "images/bgNum/0.png", posBG.bgXY),Image(root, "images/bgNum/0.png", { posBG.bgXY[1]+32, posBG.bgXY[2] }),Image(root, "images/bgNum/d.png", { posBG.bgXY[1]+64, posBG.bgXY[2] }),Image(root, "images/bgNum/0.png", { posBG.bgXY[1]+96, posBG.bgXY[2] })}
    watchface.arrowTrend = Image(root,"images/arrows/None.png", { arrowTrendPosition[1], arrowTrendPosition[2] })

	local posDelta = getItemsDeltaPosition();
    watchface.delta = {Image(root, "images/numDelta/plus.png", posDelta.deltaXY),
                       Image(root, "images/numDelta/0.png", { posDelta.deltaXY[1]+16, posDelta.deltaXY[2] }),
                       Image(root, "images/numDelta/0.png", { posDelta.deltaXY[1]+32, posDelta.deltaXY[2] }),
                       Image(root, "images/numDelta/d.png", { posDelta.deltaXY[1]+48, posDelta.deltaXY[2] }),
                       Image(root, "images/numDelta/0.png", { posDelta.deltaXY[1]+55, posDelta.deltaXY[2] })}

    local posTimeBG = getItemsTimeBGPosition();
    watchface.timeBG = {Image(root, "images/numTimeBG/0.png", posTimeBG.timeXY),
                       Image(root, "images/numTimeBG/0.png", { posTimeBG.timeXY[1]+19, posTimeBG.timeXY[2] }),
                       Image(root, "images/numTimeBG/a.png", { posTimeBG.timeXY[1]+38, posTimeBG.timeXY[2] })}
    watchface.stepArc = Image(root, "images/arcs/yellow0.png", {12,14})
    watchface.stepIcon = Image(root, "images/icons/step.png", {6,92-10})
    watchface.stepValue = {Image(root, "images/status_numbig/0.png", {6+2,96+18}), --{35+2,96}),
                       Image(root, "images/status_numbig/0.png", { 6+14+2, 96+18 }), --{ 48+2+1, 96 }),
                       Image(root, "images/status_numbig/0.png", { 6+28+2, 96+18 }),--{ 61+2+1, 96 }),
                       Image(root, "images/status_numbig/0.png", { 6+42+2, 96+18 }),--{ 74+2+1, 96 }),
                       Image(root, "images/status_numbig/0.png", { 6+56+2, 96+18 })}--{ 87+2+1, 96 })}
    dataman.subscribe("healthStepProgress", watchface.stepArc.widget, function(obj, value)
        local arc=math.floor((value // 256)*0.17)
        if arc>17 then
            arc=17
        end
        local src = string.format("images/arcs/yellow%d.png", arc)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("healthStepCount", watchface.stepIcon.widget, function(obj, value)
        local valueText = string.format("%d", value // 256)
        paintTextObjectLeft(watchface,watchface.stepValue,"images/status_numbig/%s.png",6+2, 96+18, 14,valueText)--35+2, 96, 14,valueText)
    end)
            
    watchface.calArc = Image(root, "images/arcs/orange0.png", {192-72,14})
    watchface.calIcon = Image(root, "images/icons/cal.png", {192-26,92-10}) --{192-26,92-5})
    watchface.calValue = {Image(root, "images/status_numbig/0.png", {192-8-12-56, 96+18 }),--{192-98,96}),
                           Image(root, "images/status_numbig/0.png", {192-8-12-42, 96+18 }),--{192-85, 96 }),
                           Image(root, "images/status_numbig/0.png", {192-8-12-28, 96+18 }),--{192-72, 96 }),
                           Image(root, "images/status_numbig/0.png", {192-8-12-14, 96+18 }),--{192-59, 96 }),
                           Image(root, "images/status_numbig/0.png", {192-8-12, 96+18 })}--{192-46, 96 })}
    dataman.subscribe("healthCalorieProgress", watchface.calArc.widget, function(obj, value)
        local arc=math.floor((value // 256)*0.17)
        if arc>17 then
            arc=17
        end
        local src = string.format("images/arcs/orange%d.png",arc)
        obj:set { src = imgPath(src) }
    end)
    dataman.subscribe("healthCalorieValue", watchface.calIcon.widget, function(obj, value)
        local valueText = string.format("%d", value // 256)
        paintTextObjectRight(watchface,watchface.calValue,"images/status_numbig/%s.png",192-8-12-56, 96+18, 14,valueText)--192-98, 96, 14,valueText)
    end)
                
    watchface.phoneBatteryArc = Image(root, "images/arcs/blue0.png", {12,490-74})
    watchface.phoneBatteryIcon = Image(root, "images/icons/phoneBattery.png", {6,490-108})
    watchface.phoneBatteryValue = {Image(root, "images/status_numbig/0.png", {37,490-104}),
                           Image(root, "images/status_numbig/0.png", { 51, 490-104 }),
                           Image(root, "images/status_numbig/0.png", { 64, 490-104 })}

    watchface.batArc = Image(root, "images/arcs/green0.png", {192-72,490-74})
    watchface.batIcon = Image(root, "images/icons/battery.png", {192-26,490-108})
    watchface.batValue = {Image(root, "images/status_numbig/0.png", {192-72, 490-104 }),
                          Image(root, "images/status_numbig/0.png", {192-59, 490-104 }),
                          Image(root, "images/status_numbig/0.png", {192-46, 490-104 })}
    dataman.subscribe("systemStatusBattery", watchface.batArc.widget, function(obj, value)
        local valor=value // 256;
        local arc=math.floor(valor*0.17)
        if arc>17 then
            arc=17
        end
        local src = string.format("images/arcs/green%d.png", arc)
        obj:set { src = imgPath(src) }
        local valueText = string.format("%d", math.floor(valor))
        --log(watchface,valueText)
        paintTextObjectRight(watchface,watchface.batValue,"images/status_numbig/%s.png",192-72, 490-104, 14,valueText)
    end)
    updateBGValue(watchface);
end

entry()
