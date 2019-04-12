require_relative 'modem/modem'
require 'tty-config'

config = TTY::Config.new
config.append_path(Dir.pwd)  
config.filename = 'sims'
config.read
puts config.fetch(8988303000000716519)

bg96 = Modem.new
sleep(0.5)
#bg96.setupGPIO
sleep(0.3)
#bg96.disable
#sleep(1)
#bg96.enable
#sleep(1)
#bg96.powerUp
sleep(1)
bg96.getIMEI
sleep(1)
bg96.getFirmwareInfo()
sleep(0.5)
bg96.getHardwareInfo()
sleep(0.5)
