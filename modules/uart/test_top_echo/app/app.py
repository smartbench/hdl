from pyftdi.ftdi import Ftdi
import codecs
import sys
import time
from random import randint

VID = 0x0403
PID = 0x6010
#BAUDRATE = 9600
BAUDRATE = 921600

if __name__ == '__main__' :
    ft = Ftdi()
    dev_list = ft.find_all([(VID,PID)],True)
    if(len(dev_list) > 0):
        print ("Device found:\n\t", dev_list)
        ft.open(vendor=VID,product=PID,interface=2)
        print("Opened device!")
        # if you don't do this, first byte sent never arrives to the other side
        # if you happen to know why, let us know :)
        # dummy = self.ft.read_data(1) #empty buffer
    else:
        print ("Device not connected!")
        exit()

    ft.set_baudrate(BAUDRATE)
    print("Baudrate set to {}".format(BAUDRATE))
    #ft.read_data_bytes(1)
    N = 2
    i = 0
    fifo_rd = []

    # print ("______________")
    # print( "CTS? {}\tDSR? {}\tRI? {}".format( ft.get_cts(), ft.get_dsr(), ft.get_ri() ) )
    # print( "Poll Modem status? {}\tModem Status? {}".format( ft.poll_modem_status(), ft.modem_status() ) )
    # print ("______________")
    ft.set_flowctrl('')
    ft.purge_buffers()
    ft.purge_tx_buffer()
    ft.purge_rx_buffer()
    ft.set_break(False)
    #ft.set_flowctrl()
    ft.read_data_bytes(5).tolist()

    fifo_wr = []
    for i in range(N):
        aux = (i+1)%256
        aux = randint(0,255)
        fifo_wr.append(aux)
        print ("______________")
        print( "CTS? {}\tDSR? {}\tRI? {}".format( ft.get_cts(), ft.get_dsr(), ft.get_ri() ) )
        print( "Poll Modem status? {}\tModem Status? {}".format( ft.poll_modem_status(), ft.modem_status() ) )
        print ("______________")
        print("\twrite: " + str( ft.write_data(bytes([aux])) ) , aux )
        time.sleep(0.01)
        aux = ft.read_data_bytes(5).tolist()
        if(len(aux) > 0):
            print("\tread = {}".format(aux))
            fifo_rd = fifo_rd + aux
        else:
            print ("\t...")

    print("\n... Reading more...")
    while True:
        time.sleep(2)
        aux = ft.read_data_bytes(1).tolist()
        if(len(aux)==0): break
        print("read = {}".format(aux))
        fifo_rd = fifo_rd + aux

    print ("\n>>> write fifo:\nlen = {}\ndata = {}".format(len(fifo_wr), fifo_wr))
    print ("\n>>> read fifo:\nlen = {}\ndata = {}".format(len(fifo_rd), fifo_rd))

    ft.close()
    del ft
    exit()

# from pyftdi.ftdi import Ftdi
# ft = Ftdi()
# ft.open(vendor=0x0403,product=0x6010,interface=2)
# ft.find_all([(0x0403,0x6010)],True)
# ft.set_baudrate(9600)
# rd_data = ft.read_data_bytes(1).tolist()
# rd_data
# wr_data = 131
# ft.write_data(bytes([wr_data]))
# ft.close()
