#!/usr/bin/env python

from struct import pack
from bitstruct import unpack, byteswap, calcsize
import socket
import struct
import time
import sys
import datetime
import math
import speech_recognition as sr

#UDP_PORT = 56700
LIFXPORT = 56700
LIFXsock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)        # create IP UDP socket
LIFXsock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)                         # permission to broadcast
LIFXsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)                         # avoids port problems if LIFX bulb temporarily loses connection
LIFXsock.settimeout(5)
LIFXsock.bind(('', 56700))                                                             # bind to port 56700
LIFX_IP = ''


UDPPORT = 56701 #UDP port for app comms
UDPsock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)        # create IP UDP socket
UDPsock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)                         # permission to broadcast
UDPsock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
UDPsock.bind(('', UDPPORT))   
UDPsock.settimeout(0.1)


#TCP socket for app discovery
TCP_IP = '0.0.0.0'
TCP_PORT = 56702
TCPsock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
TCPsock.bind(('',TCP_PORT))
TCPsock.settimeout(5)
TCPsock.listen(1)


#Global TCP client for communication
TCPClientSocket = None
TCPClientAddress = None
lookForInstruction = False # determines whether to accept instruction tcp connections, to not interfere with discovery protocol
instructionTCPConnected = False

#data structures for sat, bri, hue [m, d, n] and time[m,d,n]
sat = [0,0,0,0]
satCurrent = 0
deltaSat = 0
bri = [0,0,0,0]
briCurrent = 0
deltaBri = 0
hue = [0,0,0,0]
hueCurrent = 0
deltaHue = 0
goalTimes = [0,0,0,0] #m,d,n,s
timeStr = ""
timeInt = 0
transitionSpeed = 10 # choose between 5 mins, 10 mins or 15 mins
transitionInProgress = False
currentPeriod = 0
hueFactor = 0 # secs/change in value 
briFactor = 0
satFactor = 0
timeReference = [0,0,0,0] # used to update colours in colour update function
manualControlEnabled = False
sleepNowEnabled = False
errorCount = 0



#global variable for lifx address
deviceIP = ""
devicePort = 0




def newDiscoveryPacket():
    
    packet = b"\x24\x00\x00\x34\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x02\x00\x00\x00"
    return packet

def newSetColoursPacket(hue, sat, bri, trans):
    if hue < 0 or hue > 360:
        raise ValueError("hue out of range")
    if sat < 0 or sat > 100:
        raise ValueError("saturation out of range")
    if bri < 0 or bri > 100:
        raise ValueError("brightness out of range")
    if trans <0:
        raise ValueError("transition time out of range")

    def hueToDegrees(hue):
        return int(hue / 360.0 * 65535)  # degrees

    def satToPercentage(sat):
        return int(sat / 100.0 * 65535)  # percentage
    
    def briToPercentage(bri):
        return int(bri / 100.0 * 65535)  # percentage
    
    packet = b"\x31\x00\x00\x34\x00\x00\x00\x00" + b"\x00\x00\x00\x00\x00\x00\x00\x00" +b"\x00\x00\x00\x00\x00\x00\x00\x00" +b"\x00\x00\x00\x00\x00\x00\x00\x00\x66\x00\x00\x00" +b"\x00"

    packet += pack("<H", hueToDegrees(hue))             #pack as unsigned little-endian
    packet += pack("<H", satToPercentage(sat))
    packet += pack("<H", briToPercentage(bri))
    packet += pack("<H", int(3500))                     #set mid range kelvin
    packet += pack("<L", trans)
    
    return packet


def interpretPacket(bits):
    
    
    if type(bits) != bytearray:
        bits = bytearray(bits)
    
    frameFormat = 'u16u2u1u1u12u32'
    frameEndianSwap ='224'

    frameAddressFormat = 'u64u48u6u1u1u8'
    frameAddressEndianSwap = '8611'
    
    protocolHeaderFormat ='u64u16u16'                                               # bit structures from LIFX packet protocol
    protocolHeaderEndianSwap = '822'
    
    frameLength = int(calcsize(frameFormat)/8)
    frameAddressLength = int(calcsize(frameAddressFormat)/8)
    protocolHeaderLength = int(calcsize(protocolHeaderFormat)/8)                    # all /8 since we want bytes not bits
    # parse through packet
    start = 0
    end = frameLength
    frameFormatBits = bits[start:end]
    frameData = unpack(frameFormat,byteswap(frameEndianSwap,frameFormatBits))       #unpack bits into big-endian values
    
    start = end
    end = start + frameAddressLength
    frameAddressBits = bits[start:end]
    frameAddressData = unpack(frameAddressFormat,byteswap(frameAddressEndianSwap, frameAddressBits))
    
    start = end
    end = start + protocolHeaderLength
    protocolHeaderBits = bits[start:end]
    protocolHeaderData = unpack(protocolHeaderFormat,byteswap(protocolHeaderEndianSwap,protocolHeaderBits))
    
    #print('frame:',frameData)
    #print('frame address:', frameAddressData)
    #print('protocol header:',protocolHeaderData)
    
    return protocolHeaderData[1]


def discoverLIFXDevices():
    print("discovering devices...")
    broadcastIP = "255.255.255.255" #broadcast 
    for x in range(10):
        LIFXsock.sendto(newDiscoveryPacket(), (broadcastIP, LIFXPORT))
        try:
            packet,address = LIFXsock.recvfrom(1024)
        except socket.timeout:
            print('LIFX recieve timed out')
            return (0,0)
        except socket.error:
            return (0,0)
            print('LIFX socket error') 
        else:
            if(interpretPacket(packet) == 3): # 3 == StateService Message (discovery ack)
                print('bulb responded')
                deviceIP = address[0]
                devicePort = address[1]
                return (deviceIP, devicePort)
            time.sleep(0.1)
    return (0,0)


def UDPSetupListen():
        try:
            data,address = UDPsock.recvfrom(1024)
            print(data)
        except socket.timeout:
            return False
        except socket.error:
            return False
        else:
            if data == b'CS.UDP.discovery':
                msg = b'CS.UDP.discoveryACK'
                UDPsock.sendto(msg, (address[0], address[1]))
                print("UDP ack")
                data = None
                return True
            else:
                return False

def TCPSetupConnection(): # sets lookForInstruction to true, and instructionTCPConnected to false since new connection is made
        try:
            global TCPClientSocket
            global TCPClientAddress
            global TCPsock
            global lookForInstruction
            global LIFX_IP
            global deviceIP
            global devicePort
            
            if(TCPClientSocket != None):
                    TCPClientSocket.close()

            TCPsock.settimeout(5) # choose long timeout for discovering devices 
            TCPClientSocket, TCPClientAddress = TCPsock.accept()
            TCPClientSocket.settimeout(5)
            
        except socket.timeout:
            print('TCP-setup-timeout')
            return False
        except socket.error:
            return False
        else:
                try:
                    recieveData = TCPClientSocket.recv(1024)
                except socket.timeout:
                    print('TCP-setup-data-timeout')
                    return False
                except socket.error:
                    print('TCP-setup-error')
                    return False
                else:
                    if recieveData == b'CS.TCP.123456':
                            (deviceIP, devicePort) = discoverLIFXDevices()
                            if(deviceIP != 0):
                                TCPClientSocket.send(b'CS.TCP.CONNECTED') #recieved reply from bulb, tell the user via app
                                TCPClientSocket.close()
                                LIFX_IP = deviceIP
                                lookForInstruction = True
                                instructionTCPConnected = False
                                print('TCP code and bulb success')
                                TCPsock.settimeout(0.3) #                         RETURN TIMEOUT TO LOW VALUE FOR COMMUNICATION AT ANY TIME WITH APP
                                return True
                            else:
                                print('bulb not responding')
                                TCPClientSocket.send(b'CS.TCP.FALSE')
                                TCPClientSocket.close()
                                lookForInstruction = False
                                return

def TCPRecieve(): #sets instructionTCPConnected on first call
        global instructionTCPConnected
        global TCPsock
        if(instructionTCPConnected == False):
                try:
                    global TCPClientSocket
                    global TCPClientAddress

                    TCPClientSocket, TCPClientAddress = TCPsock.accept()
                    TCPClientSocket.settimeout(1000) # dont want this timing out if user interacting, might want to set to NO TIMEOUT
                except socket.timeout:
                    print('TCP-recieve-timeout')
                    return False
                except socket.error:
                    return False
                else:
                        try:   
                            recieveData = TCPClientSocket.recv(1024)
                            print('TCP data transfer accepted')
                        except socket.timeout:
                            print('TCP-receive-data-timeout')
                            return False
                        except socket.error:
                            print('TCP-receive-error')
                            return False
                        else:
                            instruction = decodeInstruction(str(recieveData))
                            instructionTCPConnected = True
                            processInstruction(instruction)
                            return True
        elif(instructionTCPConnected  == True):
                try:   
                        recieveData = TCPClientSocket.recv(1024)
                        print('TCP data transfer accepted')
                except socket.timeout:
                        print('TCP-receive-data-timeout')
                        return False
                except socket.error:
                        print('TCP-receive-error')
                        return False
                else:
                        instruction = decodeInstruction(str(recieveData))
                        instructionTCPConnected = True
                        processInstruction(instruction)
                        return True               

def decodeInstruction(instruction):
    global errorCount
    
    if(len(instruction) != 25):
        if(errorCount >5):
            mode = "XX"
            print("instruction error, terminated TCP connection")
            return (mode,mode,mode,mode,mode,mode)
        else:
            errorCount+=1
            mode = "SK"
            print("skipping instruction due to instruction error")
            return (mode,mode,mode,mode,mode,mode)
                

            
    errorCount = 0
    mode = instruction[2:4]
    hue = instruction[5:8]
    sat = instruction[9:12]
    bri = instruction [13:16]
    time = instruction[17:19] + instruction[20:22] + '00'
    trans = instruction[23]
    return (mode,hue,sat,bri,time,trans)
        #Mode:  NT - night time
        #       NC - night colour
        #       DT - day time
        #       DC - day colour
        #       MA - Manual
        #       XX - close connection AND ALSO SET instructionTCPConnected = FALSE!!!
        
def processInstruction(instruction): #m,d,n
        global TCPClientSocket
        global instructionTCPConnected
        global hue
        global bri
        global sat
        global changeTime
        global transitionSpeed
        global manualControlEnabled
        global sleepNowEnabled
        global hueCurrent
        global satCurrent
        global briCurrent

        
        print(instruction)
        if(instruction[0] == 'SK'):
            return
        if(instruction[0] == 'MT'):
            goalTimes[0] = int(instruction[4])
            timeTemporary = instruction[4]
            hours = int(timeTemporary[0:2])
            mins = int(timeTemporary[2:4])
            if(mins >= 30): # if adding 30 mins causes spill over to next hour 
                mins -= 30
                hours+=1
                if(hours==25):
                    hours = 0
            else:
                mins+=30
            if(len(str(mins)) < 2):
                mins = "0"+str(mins)
            daytime = str(hours) + str(mins)
            if(len(daytime) < 4):
                daytime = "0" + daytime
            while(len(daytime) < 6):
                daytime+="0"
            goalTimes[1] = daytime
        elif(instruction[0] == 'NT'):
            goalTimes[2] = int(instruction[4])
            timeTemporary = instruction[4]
            hours = int(timeTemporary[0:2])
            mins = (timeTemporary[2:4])
            hours+=1
            if(hours==25):
                hours = 0
            sleepTime = str(hours) + mins
            if(len(sleepTime) < 4):
                sleepTime = "0" + sleepTime
            while(len(sleepTime) < 6):
                sleepTime+="0"
            goalTimes[3] = sleepTime
            print("sleep time set", sleepTime)
        elif(instruction[0] == 'MC'):
                hue[0] = int(instruction[1])
                sat[0] = int(instruction[2])
                bri[0] = int(instruction[3])           
        elif(instruction[0] == 'DC'):
                hue[1] = int(instruction[1])
                sat[1] = int(instruction[2])
                bri[1] = int(instruction[3])
        elif(instruction[0] == 'NC'):
                hue[2] = int(instruction[1])
                sat[2] = int(instruction[2])
                bri[2] = int(instruction[3])
                hue[3] = hue[2] # for sleep time
                sat[3] = sat[2]
                bri[3] = 0
        elif(instruction[0] == 'MA'): #manual control
            if(int(instruction[5]) == 1):
                manualControlEnabled = True
            else:
                manualControlEnabled = False
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
                
            if(manualControlEnabled):
                for i in range(2): # send two to be sure
                    LIFXsock.sendto(newSetColoursPacket(int(instruction[1]),int(instruction[2]),int(instruction[3]),500), (deviceIP, devicePort))
                    time.sleep(0.1) 
        elif(instruction[0] == 'TC'): #change transition time
                if(int(instruction[5]) == 0):
                    transitionSpeed = 5 # fast
                elif(int(instruction[5]) == 1):
                    transitionSpeed = 10 # normal
                elif(int(instruction[5]) == 2):
                    transitionSpeed = 15 # slow
        elif(instruction[0] == 'SQ'): #query sleep now mode
            if(sleepNowEnabled == True):
                TCPClientSocket.send(b'1')
            else:
                TCPClientSocket.send(b'0')
            print('sleep query reply sent')
        elif(instruction[0] == 'SN'):
            if(int(instruction[5]) == 0):
                sleepNowEnabled = False
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            else:
                sleepNowEnabled = True
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,0,500), (deviceIP, devicePort))
            print('sleep mode set to', sleepNowEnabled)
                
        elif (instruction[0] == 'XX'):
                TCPClientSocket.close()
                instructionTCPConnected = False
                print('closed TCP socket')

def connectToHub():

        if(UDPSetupListen()):
                TCPSetupConnection()
                return
def timeUpdate():
    global timeStr
    global timeInt
    timeStr = str(datetime.datetime.now().strftime('%H %M %S'))
    timeInt = int(timeStr[0:2] + timeStr[3:5] + timeStr[6:8])
    #print("time Update():", timeStr)
    
def timeToSecs(timeInt):
    
    timeStr = str(timeInt)
    i = 6 - len(timeStr)
    for x in range(i):
        timeStr = '0' + timeStr # append zeros to time so multiplication doesn't return error
    hours = timeStr[0:2]
    mins = timeStr[2:4]
    secs = timeStr[4:6]
    secsFromHours = int(hours)*3600
    secsFromMins = int(mins)*60
    secs = int(secs)
    totalSecs = secsFromHours+secsFromMins+secs
    return totalSecs

def timeRemainingToNextGoal(): #secs remaining to next goal, also updates current period
    global timeInt
    global goalTimes
    global currentPeriod
    global sleepNowEnabled
    
    timeUpdate()
    currentSecs = timeToSecs(timeInt)   
    goalInSecondsList = [0,0,0,0]
    secsRemainingList = [0,0,0,0]

    for i in range(4):
        goalInSecondsList[i] = timeToSecs(goalTimes[i])
        if currentSecs > goalInSecondsList[i]:
            goalInSecondsList[i] += timeToSecs(240000) #add a day
        secsRemainingList[i] = goalInSecondsList[i] - currentSecs
    minimum = min(secsRemainingList)
    currentPeriod = secsRemainingList.index(minimum)
    if((sleepNowEnabled == True) and (currentPeriod < 3)): #current period is either fully sleeping,morning, or day
        sleepNowEnabled == False
    if((currentPeriod > 2) and (sleepNowEnabled == True)): # either waiting on bed time or sleep time
        # next period is morning which is min so use period 0
        print("sleep now enabled, next goal at:", goalTimes[0], "with secs remaining:", secsRemainingList[0], "current period:", 0)
        return secsRemainingList[0]
        
    #print("next goal at: ",goalTimes[secsRemainingList.index(minimum)], " with secs remaining:", minimum, "current period:", currentPeriod)
    return minimum

def colourTransition():
    global transitionInProgress
    global transitionSpeed
    global currentPeriod
    global hue
    global hueCurrent
    global bri
    global briCurrent
    global sa
    global satCurrent
    global deltaHue
    global deltaSat
    global deltaBri
    global hueFactor
    global briFactor
    global satFactor
    global timeReference
    global manualControlEnabled
    #global transitionComplete

    
    if((timeRemainingToNextGoal() <= (transitionSpeed*60)) and transitionInProgress == False):
        transitionInProgress = True
        timeReference = [timeRemainingToNextGoal()]*3 #[h,b,s]
        #index = nextPeriod(currentPeriod)
        deltaHue = abs(hue[currentPeriod]-hueCurrent)
        deltaBri = abs(bri[currentPeriod]-briCurrent)
        deltaSat = abs(sat[currentPeriod]-satCurrent)
        print("current hue is:", hueCurrent)
        print("current sat is:", satCurrent)
        print("current bri is:", briCurrent)
        print("delta Hue is ", deltaHue)
        print("delta Bri is ", deltaBri)   
        print("delta Sat is ", deltaSat)
        
        if(deltaHue != 0): hueFactor = int(1/(deltaHue/(transitionSpeed*60))) # how many secs per change in hue rounded down so lamp never falls behind
        if(deltaBri != 0): briFactor = int(1/(deltaBri/(transitionSpeed*60))) 
        if(deltaSat != 0): satFactor = int(1/(deltaSat/(transitionSpeed*60)))
        
        if(timeRemainingToNextGoal() < transitionSpeed*60):
            if(deltaHue != 0): hueFactor = int(1/(deltaHue/(timeRemainingToNextGoal()))) # system turn on halfway through transition
            if(deltaBri != 0): briFactor = int(1/(deltaBri/(timeRemainingToNextGoal()))) 
            if(deltaSat != 0): satFactor = int(1/(deltaSat/(timeRemainingToNextGoal())))            
 
        if(deltaHue != 0):
            if(hueFactor < 1):
                hueFactor = 1 
                if(hueCurrent<hue[currentPeriod]): hueCurrent = hue[currentPeriod] - timeRemainingToNextGoal() # change 1 val per sec for remaining secs
                elif(hueCurrent>hue[currentPeriod]): hueCurrent = hue[currentPeriod] + timeRemainingToNextGoal()
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
                print("HueCurrent bumped ", hueCurrent)
            

        if(deltaBri != 0):
            if(briFactor <1):
                briFactor = 1
                if(briCurrent<bri[currentPeriod]): briCurrent = bri[currentPeriod] - timeRemainingToNextGoal()
                elif(briCurrent>bri[currentPeriod]): briCurrent = bri[currentPeriod] + timeRemainingToNextGoal()
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
                print("BriCurrent bumped ", briCurrent)
            
        if(deltaSat != 0):
            if(satFactor <1):
                satFactor = 1
                if(satCurrent<sat[currentPeriod]): satCurrent = sat[currentPeriod] - timeRemainingToNextGoal()
                elif(satCurrent>sat[currentPeriod]): satCurrent = sat[currentPeriod] + timeRemainingToNextGoal()
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
                print("SatCurrent bumped ", satCurrent)
            
        if(deltaHue != 0):
            print("HueFactor is ", hueFactor)
        else:
            print("deltaHue is 0")
        
        if(deltaBri != 0):
            print("BriFactor is ", briFactor)
        else:
            print("deltaBri is 0")
        if(deltaSat != 0):
            print("SatFactor is ", satFactor)
        else:
            print("deltaSatis 0")
            
        print("goal time is ",timeRemainingToNextGoal()," seconds away")
                                               

        
    if(transitionInProgress == True):
        #update each of hue, bri, sat, every [factor] amount of seconds
        if(timeReference[0] - timeRemainingToNextGoal() >= hueFactor): # not activated when timeRemainingToNextGoal has increased from sleepModeNow
            timeReference[0] = timeRemainingToNextGoal() #[h,b,s]
            if(hueCurrent<hue[currentPeriod]): # if hueCurrent < hueGoal
                hueCurrent+=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            elif(hueCurrent>hue[currentPeriod]):
                hueCurrent-=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            
            print("Hue changed to:",hueCurrent)
                
        if((timeReference[1] - timeRemainingToNextGoal()) >= briFactor):
            timeReference[1] = timeRemainingToNextGoal() #[h,b,s]
            if(briCurrent<bri[currentPeriod]):
                briCurrent+=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            elif(briCurrent>bri[currentPeriod]):
                briCurrent-=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            
            print("Bri changed to:",briCurrent)
                
        if(timeReference[2] - timeRemainingToNextGoal() >= satFactor):
            timeReference[2] = timeRemainingToNextGoal() #[h,b,s]
            if(satCurrent<sat[currentPeriod]):
                satCurrent+=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            elif(satCurrent>sat[currentPeriod]):
                satCurrent-=1
                LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            print("Sat changed to:",satCurrent)
                
        if((timeRemainingToNextGoal() == 0) and ((hueCurrent != hue[currentPeriod]) or (briCurrent != bri[currentPeriod]) or (satCurrent != sat[currentPeriod]))):
            #catch scenario where time has expired and goal hasnt been met
            hueCurrent = hue[currentPeriod]
            briCurrent = bri[currentPeriod]
            satCurrent = sat[currentPeriod]
            LIFXsock.sendto(newSetColoursPacket(hueCurrent,satCurrent,briCurrent,500), (deviceIP, devicePort))
            print("values overidden to meet deadline")

            
        if(timeRemainingToNextGoal() > (transitionSpeed*60)):
            transitionInProgress = False
            

        
    
def nextPeriod(period):
    if(period == 3):
        nextPeriod = 0
        return nextPeriod
    else:
        nextPeriod = period+1
        return nextPeriod

def intoWords(string): #process speech into seperate words
    wordIndex=0 
    wordList = [0]*15
    startIndex = 0
    for x in range(len(string)):
        if string[x] == " " or x == len(string)-1:
            if(x==len(string)-1): #strange behavior around end of string fixed
                x+=1
            wordList[wordIndex] = string[startIndex:x]
            startIndex = x+1
            if(wordIndex==15):
                break
            wordIndex+=1
    return wordList[0:wordIndex]

def testIfInt(tupleInput):
    for i in range(len(tupleInput)):
        try:
            val = int(tupleInput[i])
            if(val<0 or val>360):
                return false
        except:
            return False
    return True

def sanitiseTime(timeInput):
    timeOutput = 0
    if(len(timeInput)==1):
        try:
            val = int(timeInput)
            timeOutput = '0' + timeInput + '00'
            timeOutput = int(timeOutput)
            return timeOutput
        except:
            return False

    if((len(timeInput)>=4) and (len(timeInput)<=5)):
        dividerCheck = False
        for i in range(len(timeInput)):
            if (timeInput[i] ==':'):
                dividerCheck = True
                continue
            try:
                val = int(timeInput[i]) 
            except:
                return False
        if(dividerCheck==False):
            return False
        #if function reaches here, valid input assured
        if(len(timeInput)==4):
            timeOutputString = timeInput[0] + timeInput[2:4]
            timeOutput = int(timeOutputString)
            return timeOutput
        elif(len(timeInput)==5):
            timeOutputString = timeInput[0:2] + timeInput[3:5]
            timeOutput = int(timeOutputString)
            return timeOutput
    return False
        


def processSpokenInstruction(spokenInstruction):
    if ((spokenInstruction[0] == 'set') and (len(spokenInstruction) >= 3)):
        instructionPacket = 0
        if ((spokenInstruction[1] == 'manual') and (spokenInstruction[2] == 'colour') and (len(spokenInstruction)== 6)):
            if(testIfInt((spokenInstruction[3],spokenInstruction[4],spokenInstruction[5]))): 
                instructionPacket = ("MA", spokenInstruction[3],spokenInstruction[4],spokenInstruction[5],"10:00 ", "1")
        elif ((spokenInstruction[1] == 'manual') and (spokenInstruction[2] == 'off') and (len(spokenInstruction)== 3)):
            instructionPacket = ("MA","180", "50", "50", "10:00", "0")
        elif ((spokenInstruction[1] == 'morning') and (spokenInstruction[2] == 'colour') and (len(spokenInstruction)== 6)):
            if(testIfInt((spokenInstruction[3],spokenInstruction[4],spokenInstruction[5]))): 
                instructionPacket = ("MC",spokenInstruction[3],spokenInstruction[4],spokenInstruction[5],"10:00 ","0")
        elif ((spokenInstruction[1] == 'night') and (spokenInstruction[2] == 'colour') and (len(spokenInstruction)== 6)):
            if(testIfInt((spokenInstruction[3],spokenInstruction[4],spokenInstruction[5]))): 
                instructionPacket = ("NC",spokenInstruction[3],spokenInstruction[4],spokenInstruction[5],"10:00 ","0")
        elif ((spokenInstruction[1] == 'day') and (spokenInstruction[2] == 'colour') and (len(spokenInstruction)== 6)):
            if(testIfInt((spokenInstruction[3],spokenInstruction[4],spokenInstruction[5]))): 
                instructionPacket = ("DC",spokenInstruction[3],spokenInstruction[4],spokenInstruction[5],"10:00 ","0")
        elif ((spokenInstruction[1] == 'sleep') and (len(spokenInstruction)== 4) and (spokenInstruction[3] == 'on') and (spokenInstruction[2] == 'now')):
            instructionPacket = ("SN","180", "50", "50", "10:00", "1")
        elif ((spokenInstruction[1] == 'sleep') and (len(spokenInstruction)== 4) and (spokenInstruction[3] == 'off') and (spokenInstruction[2] == 'now')):
            instructionPacket = ("SN","180", "50", "50", "10:00", "0")
        elif ((spokenInstruction[2] == 'time') and (len(spokenInstruction)== 5)):
            timeInt = sanitiseTime(spokenInstruction[3])
            if(timeInt != False):
                if(spokenInstruction[4] == 'p.m.'):
                    if(timeInt<1200):
                        timeInt += 1200
                    if(timeInt>2400):
                        timeInt-=2400
                timeStr = str(timeInt)
                while(len(timeStr) < 4):
                    timeStr = '0' + timeStr
                timeStr = timeStr[0:2] + ':' + timeStr[2:4]
                if(spokenInstruction[1] == 'morning'):
                    instructionPacket = ("MT","180", "50", "50", timeStr,"0")
                elif(spokenInstruction[1] == 'night'):
                    instructionPacket = ("NT","180", "50", "50", timeStr,"0")
    if(instructionPacket != 0):
               return instructionPacket    



def callback(recognizer,audio):
    try:
        speech = recognizer.recognize_google(audio)
    except:
        print("error interpreting words")
        speech = "error"
    spokenInstruction = intoWords(speech)
    print(spokenInstruction)
    
###setting up speech recognition
r = sr.Recognizer()
mic = sr.Microphone(device_index=2)
r.operation_timeout = 10
r.phrase_timeout = 5

with mic as source:
    r.adjust_for_ambient_noise(source, duration=1)

r.energy_threshold += 1000
print("adjusted ambience", r.energy_threshold)
r.listen_in_background(mic,callback)



if __name__ == "__main__":

    while(1):
            connectToHub()
            if(lookForInstruction):
                    TCPRecieve()
                    colourTransition()

                            
                        
                        #print('current time:', timeInt)
                        #print('goalTime:',goalTime)
                        #print('timeRemaining:', timeRemainingSecs)




                        
                        

                        
                        #for i in range(100):
                         #   LIFXsock.sendto(newSetColoursPacket(1,i,50,5000), (deviceIP, devicePort))
                          #  print(i)
                           # time.sleep(0.1)
                            
                        #for i in range(360):
                         #   LIFXsock.sendto(newSetColoursPacket(i,100,50,5000), (deviceIP, devicePort))
                          #  print("b")
                           # print(i)
                            #time.sleep(0.1)    
            



        #print('Colours Set: \nHue - ' + str(1) + ' degrees\nSaturation -  ' + str(100) + '%\nBrightness -  ' + str(50) + '%\nTransition time  - ' + str(5000) + 'ms')
    



