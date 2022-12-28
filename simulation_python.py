import random
import logging
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import Timer, RisingEdge, FallingEdge
import os
from math import *

clock_period = 100
nb_sample = 2048*4

@cocotb.coroutine
def reset_dut(reset_n, clk, duration):
    reset_n.value = 1
    yield RisingEdge(clk)
    yield Timer(duration)
    yield RisingEdge(clk)
    reset_n.value = 0

@cocotb.coroutine
def send_data(dut, data_i_o, data_q_o, data_en_o, 
    data, nco_data_i, nco_data_q, res_i, res_q, nb_cycle):
    dut.nco_i_i <= nco_data_i
    dut.nco_q_i <= nco_data_q
    dut.nco_en_i.value <= 1
    dut.data_i <= int(data)
    dut.adc_en_i.value <= 1
    yield RisingEdge(dut.clk_i)
    dut.adc_en_i.value <= 0
    dut.nco_en_i.value<= 0
    for i in range (0, nb_cycle):
        assert(int(data_en_o.value) == int(0))
        yield RisingEdge(dut.clk_i)
    assert(int(data_en_o.value) == int(1))
    assert(int(data_i_o.value.get_value_signed()) == int(res_i))
    assert(int(data_q_o.value.get_value_signed()) == int(res_q))
    yield RisingEdge(dut.clk_i)


@cocotb.test()
def verif_pulse(dut):
    #initilisation des variables
    dut.shift_val_i_dyn_1.value.signed_integer = 0
    dut.shift_val_i_dyn_2.value.signed_integer = 0
    #dut.SHIFT_ADDR_SZ_real_dyn_1.value=0
    
    
    #Filtrre complexe 1
    dut.coeff_i.value = 0
    dut.coeff_addr_i.value = 0
    dut.coeff_en_i_fir_2.value = 0
    dut.coeff_en_i_fir_1.value =0
    dut.data_i.value =0
   
    
    dut.adc_en_i.value = 0
    dut.nco_en_i.value = 0
    dut.nco_i_i.value = 0
    dut.nco_q_i.value = 0
    dut.data_i.value = 0
    
     
  

  
    
    #Test
    dut.kp_i.value = 4000
    dut.ki_i.value = 1000
    dut.kd_i.value = 5000
    dut.pid_int_rst_i.value = 0
    dut.pid_setpoint_i.value = 0
    dut.pid_sign_i.value = 0
        
    dut.shift_val_i_dyn_1.value = 0
    dut.shift_val_i_dyn_2.value = 2
    dut.SHIFT_val_real_dyn_1.value = 0
    dut.rst_i.value = 0
    dut.SHIFT_ADDR_SZ_real_dyn_1.value.signed_integer =9
    
    
    reset_n = dut.rst_i
    cocotb.fork(Clock(dut.clk_i, 10, 'ns').start())
    yield reset_dut(reset_n, dut.clk_i, 500)
    dut._log.debug("After reset")
    yield RisingEdge(dut.clk_i);

	   # load coeff filtre 1
    addr = 0
    my_coeff = []
    with open(os.getcwd() + "/coeff.txt", "r") as fd:
        for line in fd.readlines():
            dut.coeff_i.value = int(line)
            my_coeff.append(int(line))
            dut.coeff_addr_i.value = addr
            dut.coeff_en_i_fir_1.value = 1
            addr += 1
            yield RisingEdge(dut.clk_i);
    dut.coeff_en_i_fir_1.value = 0
    yield RisingEdge(dut.clk_i);
    my_coeff.reverse()

    ITER = int(pow(2,15)-1)
    START = int(-(ITER/2))
    #ITER = START
    #START=0

    # gen input and results
    data_i = [i+START for i in range(ITER)]
    data_q = [i+START for i in range(ITER)]

    print(len(data_i))

     # load coeff filtre 2
    addr = 0
    my_coeff = []
    with open(os.getcwd() + "/coeff.txt", "r") as fd:
        for line in fd.readlines():
            dut.coeff_i.value = int(line)
            my_coeff.append(int(line))
            dut.coeff_addr_i.value = addr
            dut.coeff_en_i_fir_2.value = 1
            addr += 1
            yield RisingEdge(dut.clk_i);
    dut.coeff_en_i_fir_2.value = 0
    yield RisingEdge(dut.clk_i);
    my_coeff.reverse()

    ITER = int(pow(2,15)-1)
    START = int(-(ITER/2))
    #ITER = START
    #START=0

    # gen input and results
    data_i = [i+START for i in range(ITER)]
    data_q = [i+START for i in range(ITER)]

    print(len(data_i))
    
 
	#Mixer
    shift = 15 # gain de 15 pour avoir des donnees signed sur 16bits
    nco_val_i = int(pow(2,7)-1)
    nco_val_q = int(pow(2,7)-1)+10
    dut.nco_i_i.value = 0
    dut.nco_q_i.value = 0
    yield FallingEdge(dut.clk_i)  
    for i in range (0, nb_sample):
      data = i-(nb_sample/2)
      dut.nco_i_i.value = nco_val_i
      dut.nco_q_i.value = nco_val_q
      dut.data_i.value = int(data)
      dut.adc_en_i.value = 1
      dut.nco_en_i.value = 1
      yield FallingEdge(dut.clk_i)
      dut.adc_en_i.value = dut.adc_en_i.value = 1
      dut.adc_en_i.value = 0
      dut.nco_en_i.value = 0
      yield FallingEdge(dut.clk_i)
      #dut.rst_i = int((data*dut.nco_i_i.value.signed_integer)/pow(2,shift))
      #print("lt " + str(i) + " " + str(nb_sample))
      #yield send_data(dut, data_i_o,data_q_o, data_en_o,
      #   data, nco_i, nco_q, res_i, 3)
         
         


    res_i = []
    res_q = []
    it = 0
    for i in range(0, len(data_i)-len(my_coeff), 4):
        tmpi = 0
        tmpq = 0
        ii = 0
        for coeff in my_coeff:
            vi = data_i[i+ii] * coeff
            vq = data_q[i+ii] * coeff
            tmpi += vi
            tmpq += vq
            #if (it==0):#4089):
            #    print(str(int(data_i[i+ii])) + " " +
            #        str(int(coeff)), end = ' ')
            #    print(f"{vi} {vq} ", end= ' ')
            #    print(str(int(tmpi)) + " " + str(int(tmpq))) 
            ii+=1
        it += 1
        res_i.append(tmpi)
        res_q.append(tmpq)

    # now correct behavior
    yield RisingEdge(dut.clk_i);
    print("")
    fout = open("res.txt", "w+")
    # gen and check results
    index = 0
    rd_q =0
    #for i in range(0, len(data_i)-len(my_coeff)):
    for i in range(0, 100):
        print(i)
        dut.adc_en_i.value = 1
        dut.data_i.value = data_i[i]
        yield RisingEdge(dut.clk_i)
        yield FallingEdge(dut.clk_i)
        # if (dut.data_en_o.value == 1 and len(res_i) > index):
            # rd_i = dut.data_i_o.value.signed_integer
            # fout.write(str(int(res_i[index])) + " " + str(int(dut.data_i_o.value)) + " ")
            # fout.write(str(int(res_q[index])) + " " +
            # str(int(dut.data_q_o.value)) + "\n")
            # index += 1
    fout.close()
    
    
     #Filtrre complexe 2


    res_i = []
    res_q = []
    it = 0
    for i in range(0, len(data_i)-len(my_coeff), 4):
        tmpi = 0
        tmpq = 0
        ii = 0
        for coeff in my_coeff:
            vi = data_i[i+ii] * coeff
            vq = data_q[i+ii] * coeff
            tmpi += vi
            tmpq += vq
            #if (it==0):#4089):
            #    print(str(int(data_i[i+ii])) + " " +
            #        str(int(coeff)), end = ' ')
            #    print(f"{vi} {vq} ", end= ' ')
            #    print(str(int(tmpi)) + " " + str(int(tmpq))) 
            ii+=1
        it += 1
        res_i.append(tmpi)
        res_q.append(tmpq)

    # now correct behavior
    yield RisingEdge(dut.clk_i);
   
    print("")
    fout = open("res2.txt", "w+")
    # gen and check results
    index = 0
    #for i in range(0, len(data_i)-len(my_coeff)):
    for i in range(0, 10000):
        print(i)
        dut.adc_en_i.value = 1
        dut.data_i.value = data_i[i]
        #yield RisingEdge(dut.clk_i)
        yield FallingEdge(dut.clk_i)
        # if (dut.data_en_o.value == 1 and len(res_i) > index):
            # rd_i = dut.data_i_o.value.signed_integer
            # print(str(int(res_i[index])) + " " + str(int(rd_i)), end=' ')
            # print(str(int(res_q[index])) + " " + str(int(rd_q)))
            # fout.write(str(int(res_i[index])) + " " + str(int(dut.data_i_o.value)) + " ")
            # fout.write(str(int(res_q[index])) + " " +
            # str(int(dut.data_q_o.value)) + "\n")
            # index += 1
    fout.close()
   
   
            
 
