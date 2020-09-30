#include <RF24Network.h>
#include <RF24.h>
#include <SPI.h>
#include <ADCTouch.h>

RF24 radio(7,8);                 // nRF24L01 (CE,CSN)
RF24Network network(radio);      // Include the radio in the network
const uint16_t this_node = 021;   // Address of this node in Octal format (01,02,~~)
const uint16_t node01 = 01;      // Address of the other node in Octal format(Receiver node)
unsigned long unit_number = 2;

int ref;

void setup() {
  SPI.begin();
  Serial.begin(9600);
  radio.begin();
  network.begin(125, this_node);       //(channel, node address)
  radio.setDataRate(RF24_250KBPS); 
  radio.setPALevel(RF24_PA_MAX);     // Power Level Setting

  ref = ADCTouch.read(A1, 500);
}

int tmp = 0;   // 안정적인 터치센서를 위한 임시 변수
unsigned long cnt = 0;   // 터치되었다면 각 터치센서 번호를, 안된다면 0을 저장할 변수. 이것이 전송될 것임.

void loop() {
  network.update();
  long SEN = ADCTouch.read(A1, 100);
  SEN = SEN - ref;       //remove offset

   if (tmp == 0){
      if (SEN>15){
        cnt = unit_number;
        tmp = 1;
        //===== Sending =====//
        RF24NetworkHeader header(node01);     // (Address where the data is going)
        bool ok = network.write(header, &cnt, sizeof(cnt)); // Send the data (bool이 뭔지는 모르겠음.)
        Serial.print(cnt); Serial.print('\t'); Serial.println(SEN); 
      }
     }
   else if (tmp == 1){
      if (SEN<15){
      delay(200);
        cnt = 0;
        tmp = 0;
      }
    }
    
 
 }
