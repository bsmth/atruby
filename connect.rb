require_relative 'modem/modem'
require 'tty-config'

# config = TTY::Config.new
# config.append_path(Dir.pwd)  
# config.filename = 'sims'
# config.read
# puts config.fetch(8988303000000716519)

bg96 = Modem.new
sleep(0.5)
bg96.setupGPIO
sleep(0.2)
bg96.powerUp
sleep(0.5)
bg96.enable
sleep(0.5)
bg96.sendATComm(command: "ATE1")
sleep(1)
bg96.getIMEI
sleep(1)
bg96.getFirmwareInfo
sleep(0.5)
bg96.getHardwareInfo
sleep(0.5)
bg96.getModemStatus
sleep(0.5)
bg96.setNBIoTBand('NB_ANY')
sleep(0.5)
bg96.getBandConfiguration
sleep(0.5)
bg96.setMode('NB')
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