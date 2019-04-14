require_relative 'modem/modem'
require 'tty-config'

config = TTY::Config.new
config.append_path(Dir.pwd)  
config.filename = 'sims'
config.read
puts config.fetch(8988303000000716519)

bg96 = Modem.new
bg96.clearGPIOs
sleep(0.5)
bg96.setupGPIO
sleep(0.5)
bg96.enable
sleep(0.2)
bg96.powerUp
sleep(1)
# bg96.getModemStatus
bg96.sendATComm(command: 'AT+CFUN=1')
bg96.setMode('GSM')
bg96.setGSMBand('B850')
# bg96.sendATComm(command: 'AT+QCGDEFCONT="IP","iot.1nce.net"')

# bg96.sendATComm(command:'AT+QCFG="band",0,0,80,1');
# bg96.sendATComm(command:'AT+QCFG="nwscanmode",3,1');
# bg96.sendATComm(command:'AT+QCFG="nwscanseq",030102,1');
# bg96.sendATComm(command:'AT+QCFG="iotopmode",1,1');
# bg96.sendATComm(command:'AT+QCFG="servicedomain",1,1');

# bg96.sendATComm(command: "AT+QICSGP=1,1,\"iot.1nce.net\",\"\",\"\",1")
sleep(1)
# bg96.sendATComm(command: 'AT+CFUN=1')
sleep(1)
# bg96.sendATComm(command: 'AT+COPS=1,2,"26201",9')
# sleep(1)
bg96.getIMEI
# sleep(1)
bg96.getFirmwareInfo
sleep(0.5)
bg96.getHardwareInfo
sleep(0.5)
bg96.getModemStatus

sleep(0.5)
bg96.getSignalQuality
sleep(0.5)
bg96.getQueryNetworkInfo
sleep(0.5)
bg96.connectToOperator
sleep(0.5)
# bg96.getFixedLocation
sleep(0.5)
bg96.turnOnUserLED
sleep(0.5)
bg96.turnOffUserLED