from pyftdi.ftdi import Ftdi
import codecs
import sys
import time

VID = 0x0403
PID = 0x6010
BAUDRATE_9600 = 9600
BAUDRATE_921600 = 921600

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

    ft.set_baudrate(BAUDRATE_9600)
    #ft.read_data_bytes(1)
    i = 0
    fifo_rd = []
    fifo_wr = []
    for i in range(20):
        aux = (i+1)%256
        fifo_wr.append(aux)
        print("write: " + str( ft.write_data(bytes([aux])) ) , aux )
        time.sleep(0.1)
        aux = ft.read_data_bytes(5).tolist()
        if(len(aux) > 0):
            print("read = {}".format(aux))
            fifo_rd = fifo_rd + aux
        else:
            print ("...")

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
