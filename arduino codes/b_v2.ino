/*
  Arduino Wireless Network - Multiple NRF24L01 Tutorial
          == Base/ Master Node 00==
  by Dejan, www.HowToMechatronics.com
  Libraries:
  nRF24/RF24, https://github.com/nRF24/RF24
  nRF24/RF24Network, https://github.com/nRF24/RF24Network
*/

#include <RF24Network.h>
#include <RF24.h>
#include <SPI.h>

RF24 radio(7,8);                 // nRF24L01 (CE,CSN)
RF24Network network(radio);      // Include the radio in the network
const uint16_t this_node = 00;   // Address of this node in Octal format ( 04,031, etc)

void setup() {
  SPI.begin();
  Serial.begin(9600);
  radio.begin();
  network.begin(125, this_node);       // (channel, node address)
  radio.setPALevel(RF24_PA_MAX);     // Power Level setting
  radio.setDataRate(RF24_250KBPS);
}

void loop() {
  bool netstate;
  network.update();
  //===== Receiving =====//
  if ( netstate = network.available()) {     // Is there any incoming data?
    RF24NetworkHeader header;
    unsigned long incomingData;
    network.read(header, &incomingData, sizeof(incomingData));// Read the incoming data

    Serial.println((long)incomingData);
  }
}
