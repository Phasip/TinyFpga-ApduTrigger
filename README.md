This is a quick hack to use a TinyFPGA to send a trigger signal
when pre-defined APDU data is sent to a SIMcard (or any IS7816 card)
Trigger goes down when a response is incomming.
Starts looking for new trigger as soon as first trigger found, no
need to reset the circuit.

You need to enter Fd and Dd manually in the code.
authenticate_SIM_ISO7816.tv is the recording of an 3G Authenticate command
with RAND=[0xAA]*16, and AUTN=[0xBB]*16

Has only been tested on TinyFPGA BX, but it only uses 105 cells so it may
work on the TinyFPGA A1

### Usage (simulation)
```
gunzip authenticate_SIM_ISO7816.tv.gz
apio sim
```

### Usage (IRL)
```
apio upload 
```


