
#include <RF24Network.h>
#include <RF24.h>
#include <SPI.h>

RF24 radio(7,8);               // nRF24L01 (CE,CSN)
RF24Network network(radio);      // Include the radio in the network
const uint16_t this_node = 01;  // Address of our node in Octal format ( 04,031, etc)
const uint16_t base00 = 00;    // Address of the other node in Octal format

void setup() {
  
  SPI.begin();
  Serial.begin(9600);
  radio.begin();
  network.begin(125, this_node);  //(channel, node address)
  radio.setDataRate(RF24_250KBPS);
  radio.setPALevel(RF24_PA_MAX);
}

void loop() {
  network.update();
  //===== Receiving =====//
  if ( network.available() ) {     // Is there any incoming data?
    RF24NetworkHeader header;
    unsigned long touchState;
    network.read(header, &touchState, sizeof(touchState)); // Read the incoming data
    Serial.println((long)touchState);         // incoming data check
  //==== Sending ====//
    unsigned long nodeNumber = touchState;
    RF24NetworkHeader header2(base00);
    bool ok = network.write(header2, &nodeNumber, sizeof(nodeNumber));
  }
}
