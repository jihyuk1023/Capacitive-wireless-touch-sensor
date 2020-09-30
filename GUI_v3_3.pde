/*
https://startingelectronics.org/software/processing/find-arduino-port/
*/
import processing.serial.*;
import javax.swing.JOptionPane; // Had to change this which meant showMessageDialog() changes
final boolean debugPort = true; 
import static javax.swing.JOptionPane.*;

Serial myPort;
PFont myFont;
Table table;
int STATE;
int saveSTATE;
int correction;
Object selectedValue;
String response = "";
String MD = month() + "/" + day(); 
int savedTime, passedTime, leftTime = 180;
int COLCNT;
int n = 1; //차전
int rnd = 1; //라운드
int[] arr = new int[14];        //아두이노로 부터 받은 점수
int arrtmp;
boolean sensor = false;
int[] teamscore = new int[5];   //팀 점수
int[] score = new int[10];     // 당일 개인 점수
int[] totscore = new int[40];  //개인 총 점수
int[] A_Score = new int[5];    //왼쪽 점수창
int[] B_Score = new int[5];    //오른쪽 점수창

//============ loaded data ============//
int[] id = new int[40];         //메모장에서 불러온 아이디를 적어두는 배열
String[] name = new String[40]; //메모장에서 불러온 이름을 적어두는 배열
int[] loadscore = new int[40];  //메모장에서 불러온 점수를 적어두는 배열
int[] LOADscore = new int[40];

//============ saving data ============//
String[] TEAM = {"윈디", "써니", "루나", "스텔라", "클라우디"}; //gui에 내장된 팀 명(메모장 작성 시 메모장에 저장됨)
int[] ID = new int[40];         //gui에 내장된 id(메모장 작성 시 메모장에 저장됨)
{
  for(int i = 0; i < 40; i++)
    ID[i] = i+1;
}
String[] NAME = new String[40]; //gui에 내장된 개인 이름(메모장 작성 시 메모장에 저장됨)
{
  for(int i = 0; i < 40; i++){
   if(i < 8)
    NAME[i] = "윈디" + Integer.toString(i + 1);
   if(i >= 8 && i < 16)
    NAME[i] = "써니" + Integer.toString(i % 8 + 1);
   if(i >= 16 && i < 24)
    NAME[i] = "루나" + Integer.toString(i % 8 + 1);
   if(i >= 24 && i < 32)
    NAME[i] = "스텔라" + Integer.toString(i % 8 + 1);
   if(i >= 32 && i < 40)
    NAME[i] = "클라우" + Integer.toString(i % 8 + 1);
  }
}

void setup(){
    size(displayWidth, displayHeight);
    int num_ports;
    boolean device_detected = false;
    String[] port_list;
    String detected_port = "";

    println(Serial.list());
    
    // get the number of detected serial ports
    num_ports = Serial.list().length;
    // save the current list of serial ports
    port_list = new String[num_ports];
    for (int i = 0; i < num_ports; i++) {
        port_list[i] = Serial.list()[i];
    }
    
    JOptionPane.showMessageDialog(frame,
    "1. Base or USB device must be unplugged.\n" +
    "   (unplug device and restart this application if not)\n\n" +
    "2. Plug the Base device into a USB port\n");
    
    while(!device_detected){
    // see if Arduino or serial device was plugged in
      if ((Serial.list().length > num_ports) && !device_detected) {
        device_detected = true;
        // determine which port the device was plugge into
        boolean str_match = false;
        if (num_ports == 0) {
          detected_port = Serial.list()[0];
        }
        else {
          // go through the current port list
          for (int i = 0; i < Serial.list().length; i++){ 
            // go through the saved port list
            for (int j = 0; j < num_ports; j++) {
              if (Serial.list()[i].equals(port_list[j])) {
                break;
              }
              if (j == (num_ports - 1)) {
                str_match = true;
                detected_port = Serial.list()[i];
              }
            }
          }
        }
      }
    
      // calculate and display serial port name
      if (device_detected) {
        break;
      }
    }
    /*이 위치에 시리얼 포트 재선언*/
    myPort = new Serial(this, detected_port, 9600);
    myPort.bufferUntil('\n');       
  
  //===== Font Setting =====//        
  String[] fontList = PFont.list();
  printArray(fontList); 
  myFont = createFont("나눔스퀘어라운드 ExtraBold", 32);
  textFont(myFont); 
  
  background(0);
  
  //===== 내부적으로 돌아갈 ingamedata 테이블 =====//
  try{
    //===== 값 읽기 =====//    
    table = loadTable("ingamedata.tsv", "header");
    
    println(table.getColumnCount() + " total columns in table");
    
    int colcnt = COLCNT = table.getColumnCount() - 2; //column의 개수를 새서 colcnt에 저장. -2는 앞의 두개의 행을 빼기 위함.
    n = table.getInt(0, colcnt + 1);//getInt(row, col)
    rnd = table.getInt(1, colcnt + 1);
    
    for(int i = 0; i < 40; i++){
      TableRow row = table.getRow(i+3);
      id[i] = row.getInt("id");
      name[i] = row.getString("name");
      LOADscore[i] = loadscore[i] = row.getInt(colcnt+1);//table.getInt(i+1, table.getColumnCount()-1);
    }
    
    //팀 점수 표시
   for(int i = 0; i < 5; i++)
     for(int j = 0; j < 8; j++)
       teamscore[i] += loadscore[i * 8 + j];
    
  }

  catch(Exception e){  
    //===== 새 테이블 세팅 =====//
     println("ingamedata.tsv does not exist or could not be read");
     println("create new table");
  
    table = new Table();
    table.addColumn("id");
    table.addColumn("name");
    table.addColumn(Integer.toString(rnd));  
  
    TableRow firstRow = table.addRow();
    firstRow.setString("id", MD);
    firstRow.setString("name", "n차전 :");
    firstRow.setString(Integer.toString(rnd), Integer.toString(n));
    TableRow secondRow = table.addRow();
    secondRow.setString("name", "라운드 :");
    secondRow.setString(Integer.toString(rnd), Integer.toString(rnd));

    TableRow newRow = table.addRow();
    for(int i = 0; i < 40; i++){ 
      newRow = table.addRow();
      newRow.setInt("id", ID[i]);
      newRow.setString("name", NAME[i]);
      newRow.setInt(Integer.toString(rnd), totscore[i]);
    }
    
  saveTable(table, "data/ingamedata.tsv");
  for(int i = 0; i < 40; i++)
    name[i] = NAME[i];
  }  
  
  sportSelect(rnd);
  sumTotscore(n);  
}

  //====== 문자열 분리 함수 =====//
void serialEvent(Serial p){
  if(STATE == 1){ //STATE 1 : 읽기
   response = p.readStringUntil('\n').trim();
   arrtmp = int(response);
  
   for(int i = 0; i < 14; i++)
    if(arrtmp == i + 1)
      arr[i]++; 
  }
}

//====== 배열 초기화 함수 =======//
int tmp1 = 0, tmp2 = 0;
void initializeArray(int rnd, int n){
   if(rnd != tmp1){ //rnd값이 바뀔때만 작동되도록 함
     //------- 좌측 우측 점수 배열 초기화 -------//
      for(int j = 0; j < 5; j++)
        A_Score[j] = B_Score[j] = 0;
       tmp1 = rnd;
    }
    if(n != tmp2){ //n값이 바뀔떄만 작동되도록 함
     //------- 누적된 개인 당일 점수 배열 초기화-------//
      for(int j = 0; j < 10; j++)
        score[j] = 0;     
       tmp2 = n;
    }
}

 //====== 각 라운드에 맞춰 경기 종목을 선택하는 함수 ======//  
void sportSelect(int rnd){
  int i = rnd - 1; 

  A_Score[4-(i+4)%5] = arr[0];           B_Score[4-(i+4)%5] = arr[1];
  A_Score[4-(i+3)%5] = arr[2];           B_Score[4-(i+3)%5] = arr[3];
  A_Score[4-(i+2)%5] = arr[4] + arr[5];  B_Score[4-(i+2)%5] = arr[6]+arr[7];
  A_Score[4-(i+1)%5] = arr[8];           B_Score[4-(i+1)%5] = arr[9];
  A_Score[4-i%5] = arr[10]+arr[11];      B_Score[4-i%5] = arr[12]+arr[13]; 
}

void sumScore(){
  //------ 좌측의 경기 점수를 개인 당일 점수에 누적 ------// 
    score[0] += A_Score[0];  score[1] += B_Score[0];
    score[2] += A_Score[1];  score[3] += B_Score[1];
    score[4] += A_Score[2];  score[5] += B_Score[2];
    score[6] += A_Score[3];  score[7] += B_Score[3];
    score[8] += A_Score[4];  score[9] += B_Score[4];
}

void subScore(){
    score[0] -= A_Score[0];  score[1] -= B_Score[0];
    score[2] -= A_Score[1];  score[3] -= B_Score[1];
    score[4] -= A_Score[2];  score[5] -= B_Score[2];
    score[6] -= A_Score[3];  score[7] -= B_Score[3];
    score[8] -= A_Score[4];  score[9] -= B_Score[4];
}

//====== 경기에 참여하는 10명의 플레이어의 기존점수에 새로 추가된 점수를 누적 ======//
int tmp4=1;
void sumTotscore(int n){
  
  
    for(int k = 0; k < 40; k++)
    totscore[k] = loadscore[k];
      
  //------ 플레이어 선택 ------//
    int m = n - 1;
    for(int j = 0; j< 5; j++){
      totscore[2*(m%4)+8*j] += score[2*j];
      totscore[2*(m%4)+1+8*j] += score[2*j+1];  
    }
}

int saveData(){
   table = loadTable("ingamedata.tsv", "header");
   int colcnt = table.getColumnCount() - 2; //column의 개수를 새서 colcnt에 저장. -2는 앞의 두개의 행을 빼기 위함.
   
   //------- 개인 누적 점수 totscore를 저장 ---------//
   if(rnd == table.getInt(1, colcnt + 1)){ //동일 라운드에서 저장하면 덮어쓰기
     TableRow newRow = table.getRow(0);
     newRow.setInt(colcnt + 1, n);
     newRow = table.getRow(1);
     newRow.setInt(colcnt + 1, rnd);
 
     for(int i = 0; i < 40; i++){ 
      newRow = table.getRow(i+3);
      newRow.setInt(Integer.toString(colcnt), totscore[i]); 
     }
  
     saveTable(table, "data/ingamedata.tsv");
     
   }
   else{
     table.addColumn(Integer.toString(colcnt+1));  //이전과 다른 라운드에서 저장하면 새 column추가
     TableRow newRow = table.getRow(0);
     newRow.setInt(colcnt + 2, n);
     newRow = table.getRow(1);
     newRow.setInt(colcnt + 2, rnd);
 
     for(int i = 0; i < 40; i++){ 
      newRow = table.getRow(i+3);
      newRow.setInt(Integer.toString(colcnt+1), totscore[i]); 
     }
  
     saveTable(table, "data/ingamedata.tsv");
   }

  return 1;
}

void mousePressed(){
  
  //====== 종료  ======//
  if(mouseX > 14.36/15 * width && mouseY > 0.5/14.5 * height && mouseX < 14.96/15 * width && mouseY < 1.5/14 * height)
  {
    int ext = showConfirmDialog(null, "현재까지의 내용을 엑셀 파일로 저장하고 종료하시겠습니까?", "Exit", YES_NO_OPTION);
    
    if( ext == 0 ){
       sportSelect(rnd);
       sumTotscore(n);  
       
      try{
        String newCol = MD + "-" + Integer.toString(n);
        table = loadTable("gamedata.csv", "header");
        table.addColumn(newCol);
        TableRow newRow = table.getRow(0);
        for(int i = 0; i < 40; i++){ 
        newRow = table.getRow(i+1);
        newRow.setInt(newCol, totscore[i]); 
       }
        saveTable(table, "data/gamedata.csv");
      
      }
      catch(Exception e){
       String newCol = MD + "[" + Integer.toString(n) +"]";
       println("create new table");
       table = new Table();
       table.addColumn("id");
       table.addColumn("name");
       table.addColumn(newCol);
       TableRow newRow = table.addRow();
       for(int i = 0; i < 40; i++){ 
          newRow = table.addRow();
          newRow.setInt("id", ID[i]);
          newRow.setString("name", name[i]);
          newRow.setInt(newCol, totscore[i]);
        }
        saveTable(table, "data/gamedata.csv");
      }
      exit();
    }
  }
  
  //===== 센서 =====//
  if(mouseX > 0 && mouseY > 0.8/14.5 * height && mouseX < 0.67/15 * width && mouseY < 3.3/14.5 * height){
    STATE = 0; 
    sensor = !sensor;//showConfirmDialog(null, "센서 ON/OFF", "Sensor ON/OFF", YES_NO_OPTION);
     if(sensor == true){
       STATE = 1;
     }
     else if(sensor == false){
       STATE = 0;
       sportSelect(rnd);
       sumScore();
       sumTotscore(n);
     /*  //팀 점수 표시
       for(int i = 0; i < 5; i++)
         teamscore[i] = 0;
       for(int i = 0; i < 5; i++)
         for(int j = 0; j < 8; j++)
           teamscore[i] += totscore[i * 8 + j]; */
     }
  }
  
  //===== 이전 라운드 =====//
  if(mouseX > 0 && mouseY > 3.4/14.5 * height && mouseX < 0.67/15 * width && mouseY < 5.9/14.5 * height){
     int befRnd = showConfirmDialog(null, "이전 라운드로 돌아가시겠습니까? 현재 라운드의 기록은 지워집니다.", "Before Round", YES_NO_OPTION);
     if(befRnd == 0){
       STATE = 0;//2;
       if(saveSTATE == 0)
         saveData();
       
       table = loadTable("ingamedata.tsv", "header");

       int colcnt = table.getColumnCount() - 2; //column의 개수를 새서 colcnt에 저장. -2는 앞의 두개의 행을 빼기 위함.
       n = table.getInt(0, colcnt + 1);//getInt(row, col)
       rnd = table.getInt(1, colcnt + 1);
       
       if(colcnt == COLCNT)
         showMessageDialog(frame, "금일 진행된 경기에 대해서만 이전 라운드의 조회가 가능합니다", "System error", ERROR_MESSAGE);
       else if(colcnt > 1 || (colcnt == 1 && selectedValue == "초기화")){
         rnd--;       
         if(rnd == 0){
           n--;
           rnd = 5;
         }
         
         for(; rnd == table.getInt(1, colcnt + 1); colcnt--); //이전 라운드가 존재하는 colcnt값을 탐색.
         for(int i = 0; i < 40; i++){
          TableRow row = table.getRow(i+3);
            totscore[i] = loadscore[i] = row.getInt(colcnt);
         }
    
          int m = n - 1;
           score[0] = totscore[0 + 2*(m%4)] - LOADscore[0 + 2*(m%4)];
           score[1] = totscore[1 + 2*(m%4)] - LOADscore[1 + 2*(m%4)];
           score[2] = totscore[8 + 2*(m%4)] - LOADscore[8 + 2*(m%4)];
           score[3] = totscore[9 + 2*(m%4)] - LOADscore[9 + 2*(m%4)];
           score[4] = totscore[16 + 2*(m%4)] - LOADscore[16 + 2*(m%4)];
           score[5] = totscore[17 + 2*(m%4)] - LOADscore[17 + 2*(m%4)];
           score[6] = totscore[24 + 2*(m%4)] - LOADscore[24 + 2*(m%4)];
           score[7] = totscore[25 + 2*(m%4)] - LOADscore[25 + 2*(m%4)];
           score[8] = totscore[32 + 2*(m%4)] - LOADscore[32 + 2*(m%4)];
           score[9] = totscore[33 + 2*(m%4)] - LOADscore[33 + 2*(m%4)];
         
         for(; colcnt == table.getColumnCount() - 2; colcnt++)
           table.removeColumn(colcnt+1);
           
       tmp1 = 0; tmp2 = n; initializeArray(rnd, n);//tmp1을 실제 rnd와 다른 값으로 바꿔서 항상 score[]가 초기화되도록 함
       
       for(int i = 0; i < 14; i++) 
         arr[i] = 0;
         
       //팀 점수 표시
       for(int i = 0; i < 5; i++)
         teamscore[i] = 0;
       for(int i = 0; i < 5; i++)
         for(int j = 0; j < 8; j++)
           teamscore[i] += totscore[i * 8 + j];
       
       }
       else{
         showMessageDialog(frame, "이전 라운드에 대한 정보가 없습니다.", "System error", ERROR_MESSAGE);
       }

         saveTable(table, "data/ingamedata.tsv");
     }
}
  
  //===== 초기화 / 저장 =====//
  if(mouseX > 0 && mouseY > 6.0/14.5 * height && mouseX < 0.67/15 * width && mouseY < 8.5/14.5 * height){
    if(STATE == 1){ //센서 버튼의 기능을 복붙
       STATE = 0;
       sportSelect(rnd);
       sumScore();
       sumTotscore(n);
       //팀 점수 표시
       for(int i = 0; i < 5; i++)
         teamscore[i] = 0;
       for(int i = 0; i < 5; i++)
         for(int j = 0; j < 8; j++)
           teamscore[i] += totscore[i * 8 + j];
       
    }
    
    Object[] possibleValues = { "리셋", "저장"}; 
    Object selectedValue = showInputDialog(null, "현재 라운드를 리셋 혹은 저장 하시겠습니까?", "Restart Round/Save",JOptionPane.INFORMATION_MESSAGE, 
     null, possibleValues, possibleValues[1]);
     //-------- 리셋 ------//
     if(selectedValue == "리셋"){ 
       table = loadTable("ingamedata.tsv", "header");
       
       int colcnt = table.getColumnCount() - 2; //column의 개수를 새서 colcnt에 저장. -2는 앞의 두개의 행을 빼기 위함.
       //-------- 마지막 column 점수 불러오기 ------//
       for(int i = 0; i < 40; i++){
          TableRow row = table.getRow(i+3);
          loadscore[i] = row.getInt(colcnt+1);//table.getInt(i+1, table.getColumnCount()-1);
       }
 
       saveTable(table, "data/ingamedata.tsv");
       
       subScore();  //뺄셈임. sumScore가 아님에 주의.
       sumTotscore(n);
       
       for(int i = 0; i < 14; i++) arr[i] = 0;
       tmp1 = 0; tmp2 = n;
       initializeArray(rnd, n);//tmp1을 실제 rnd와 다른 값으로 바꿔서 항상 score[]가 초기화되도록 함
   
   }
     //------- 저장 ---------//
     else if(selectedValue == "저장"){ 
     saveSTATE = saveData();
     sportSelect(rnd);
     if(correction != 0){
       sumScore();
       sumTotscore(n);
       correction = 0;
     }
       //팀 점수 표시
       for(int i = 0; i < 5; i++)
         teamscore[i] = 0;
       for(int i = 0; i < 5; i++)
         for(int j = 0; j < 8; j++)
           teamscore[i] += totscore[i * 8 + j];
       
     STATE = 0;//2;
     }
}
  
  //===== 다음 라운드 =====//
  if(mouseX > 0 && mouseY > 8.6/14.5 * height && mouseX < 0.67/15 * width && mouseY < 11.1/14.5 * height){
    int nxtRnd = showConfirmDialog(null, "다음 라운드로 넘어가시겠습니까?", "Next Round", YES_NO_OPTION);
     if(nxtRnd == 0){
       if(saveSTATE == 0){
          saveData();
          sportSelect(rnd);
           //sumScore();
           sumTotscore(n);
           //팀 점수 표시
           for(int i = 0; i < 5; i++)
             teamscore[i] = 0;
           for(int i = 0; i < 5; i++)
             for(int j = 0; j < 8; j++)
               teamscore[i] += totscore[i * 8 + j];
       }
       
       table = loadTable("ingamedata.tsv", "header");
       
       int colcnt = table.getColumnCount() - 2; //column의 개수를 새서 colcnt에 저장. -2는 앞의 두개의 행을 빼기 위함.
       n = table.getInt(0, colcnt + 1);//getInt(row, col)
       rnd = table.getInt(1, colcnt + 1);
       
       //------- 라운드와 차전의 변경에 맞춰 종목과 플레이어 교체 -------//
       rnd++;       
       if(rnd == 6){
         n++;
         rnd = 1;
         for(int i = 0; i < 10; i++)
         score[i]=0;
         
         for(int i = 0; i < 40; i++){
          TableRow row = table.getRow(i+3);
          loadscore[i] = row.getInt(colcnt+1);//table.getInt(i+1, table.getColumnCount()-1);
          //sumTotscore(n)는 loadscore[]를 이용해서 totscore[]값을 초기화하므로 다음 차전으로 넘어갈때마다 loadscore를 업데이트 함
         }
       }
       
       for(int i = 0; i < 14; i++) arr[i] = 0;
       sportSelect(rnd);
       sumTotscore(n);
       
       //팀 점수 표시
       for(int i = 0; i < 5; i++)
         teamscore[i] = 0;
       for(int i = 0; i < 5; i++){
         for(int j = 0; j < 8; j++){
           teamscore[i] += totscore[i * 8 + j];}}
     }
     STATE = 0;//2; 
     saveSTATE = 0;
     sensor = false;
  }
  
  //===== 수정 =====//
  if(mouseX > 0 && mouseY > 11.2/14.5 * height && mouseX < 0.67/15 * width && mouseY < 16.7/14.5 * height){
   STATE = 0;
    correction = showConfirmDialog(null, "수정 ON/OFF", "Correction ON/OFF", YES_NO_OPTION);
    if(correction == 0){
      subScore();
      String correct = showInputDialog("점수를 변경합니다. (예 : 슈퍼맨1/20)");
      try{
      String[] list = split(correct, "/");
      int cscore = Integer.parseInt(list[1]); //수정된 점수
      int list_num = Integer.parseInt(list[0].substring(list[0].length()-1, list[0].length())); // A or B
      String list_name = list[0].substring(list[0].length()-list[0].length(),list[0].length()-1); // 경기 이름

      switch(list_name){
        case "슈퍼맨":
          if(list_num == 1)
            A_Score[0] += cscore;
          else
            B_Score[0] += cscore;
          break;
         
        case "잽":
          if(list_num == 1)
            A_Score[1] += cscore;
          else
            B_Score[1] += cscore;
          break;
            
        case "비틀어당기기":
          if(list_num == 1)
            A_Score[2] += cscore;
          else
            B_Score[2] += cscore;
          break;
         
        case "팔펴기":
          if(list_num == 1)
            A_Score[3] += cscore;
          else
            B_Score[3] += cscore;
          break;
            
        case "팔올리기":
          if(list_num == 1)
            A_Score[4] += cscore;
          else
            B_Score[4] += cscore;
          break;
         
         default:
           showMessageDialog(frame, "입력정보를 다시 확인하세요. (예 : [종목][왼1,오2]/[가감 점수])", "System Error", ERROR_MESSAGE);
        }
        sumScore();
        sumTotscore(n);
      }catch(Exception e){showMessageDialog(frame, "입력정보를 다시 확인하세요. (예 : [종목][왼1,오2]/[가감 점수])", "System Error", ERROR_MESSAGE);}  
    }
  }
}

void draw(){ 
  
  background(#17223b);
  //====== 타이머 표시 창 ======//
  if(STATE == 1){
    passedTime = minute() * 60 + second() - savedTime;
    leftTime = 179 - passedTime;
    if(leftTime == -1){
       STATE = 0;
       mousePressed();
       mouseX = 30/1500 * width; //[센서 ON]버튼의 좌표
       mouseY = 15/145 * height;
       sensor = false;  //센서를 OFF 상태로 만듦.
       showMessageDialog(frame, "경기가 종료되었습니다", "Time Over", YES_OPTION);
    }
      if(leftTime >= 10){ textSize(40);    textAlign(LEFT, CENTER); 
      text(leftTime/60+ ":" + leftTime%60, 1.868/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);}
      else if(leftTime < 10){ textSize(60);    textAlign(LEFT, CENTER);   fill(#E33434); 
      text(leftTime/60+ ":" + leftTime%60, 1.80/15 * width, 0.40/14.5 * height, 2.36/15 * width, 1.4/14.5 * height);}
  }
  else{
    savedTime = minute() * 60 + second();
    leftTime = 180;
    textSize(40);    textAlign(LEFT, CENTER);
    text("3:00", 1.868/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  }
 
 
    
  //====== 종료 버튼 창 =====//
  fill(#ff5748);  
  rect(14.36/15 * width, 0.5/14.5 * height, 0.6/15 * width, 1/14.5 * height, 10, 10, 10, 10);
  textSize(25);textAlign(CENTER, CENTER); 
  fill(255); 
  text("종료", 14.36/15 * width, 0.5/14.5 * height, 0.6/15 * width, 1/14.5 * height);  
  
  //====== 좌측 버튼 창 (위의 컨트롤 버튼을 여기 넣어도 될 듯) =====//
  textSize(30);
  fill(#005792);
  rect(0, 0.5/14.5 * height, 0.73/15 * width, 13.5/14.5 * height, 0, 10, 10, 0);
  
  fill(#ff6768);  rect(0, 0.8/14.5 * height, 0.67/15 * width, 2.5/14.5 * height, 0, 10, 10, 0);
  if(STATE==1){fill(#f6f6e0);     text("센서 OFF",0, 0.8/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);}
  else {fill(#fcc4b6);            text("센서 ON", 0, 0.8/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);}
  fill(#ff7768);  rect(0, 3.4/14.5 * height, 0.67/15 * width, 2.5/14.5 * height, 0, 10, 10, 0);
  fill(#f6f6e9);     text("이전",0, 3.4/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);
  fill(#ff8768);  rect(0, 6.0/14.5 * height, 0.67/15 * width, 2.5/14.5 * height, 0, 10, 10, 0);
  fill(#f6f6e9);     text("리셋\n/\n저장", 0, 6.0/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);
  fill(#ff9768);  rect(0, 8.6/14.5 * height, 0.67/15 * width, 2.5/14.5 * height, 0, 10, 10, 0);
  fill(#f6f6e9);     text("다음", 0, 8.6/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);
  fill(#ffa768);  rect(0, 11.2/14.5 * height, 0.67/15 * width, 2.5/14.5 * height, 0, 10, 10, 0);
  fill(#f6f6e9);     text("수정", 0, 11.2/14.5 * height, 0.67/15 * width, 2.5/14.5 * height);
  
  //====== n 차전 및 팀 점수 창 ======// 
  textSize(40);
  fill(#005792);
  rect(3.46/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height, 10, 0, 0, 0);
  fill(#005792);
  rect(5.62/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  fill(#005792);
  rect(7.78/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  fill(#005792);
  rect(9.94/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  fill(#005792);
  rect(12.1/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height, 0, 10, 0, 0);
  
  noFill();
  rect(3.46/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height, 0, 0, 0, 10);
  rect(5.62/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  rect(7.78/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  rect(9.94/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  rect(12.1/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height, 0, 0, 10, 0);
  
  //------ 팀 명 출력 -------//
     textSize(40);
     textAlign(CENTER, CENTER); 
     fill(#f6f6e9); 
     text(n + "차 / " + rnd + "경기", 1.2/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     textSize(35);
     textAlign(CENTER, CENTER); 
     fill(#f6f6e9); 
     text(TEAM[0], 3.46/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(TEAM[1], 5.62/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(TEAM[2], 7.78/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(TEAM[3], 9.94/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(TEAM[4], 12.1/15 * width, 0.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  //------ 팀 점수 출력 ------//
     fill(#f6f6e9); 
     text(Integer.toString(teamscore[0]), 3.46/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(Integer.toString(teamscore[1]), 5.62/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(Integer.toString(teamscore[2]), 7.78/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(Integer.toString(teamscore[3]), 9.94/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
     fill(#f6f6e9); 
     text(Integer.toString(teamscore[4]), 12.1/15 * width, 1.5/14.5 * height, 2.16/15 * width, 1/14.5 * height);
  
  //====== 종목 및 카운팅 창 ======//
  fill(#005792);
  rect(1.2/15 * width, 3.0/14.5 * height, 2.2/15 * width, 2/14.5 * height, 10);
  rect(1.2/15 * width, 5.25/14.5 * height, 2.2/15 * width, 2/14.5 * height, 10);
  rect(1.2/15 * width, 7.5/14.5 * height, 2.2/15 * width, 2/14.5 * height, 10);
  rect(1.2/15 * width, 9.75/14.5 * height, 2.2/15 * width, 2/14.5 * height, 10);
  rect(1.2/15 * width, 12.0/14.5 * height, 2.2/15 * width, 2/14.5 * height, 10);
  
  noFill();
  rect(3.5/15 * width, 3.0/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  rect(6.2/15 * width, 3.0/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  
  rect(3.5/15 * width, 5.25/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  rect(6.2/15 * width, 5.25/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  
  rect(3.5/15 * width, 7.5/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  rect(6.2/15 * width, 7.5/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  
  rect(3.5/15 * width, 9.75/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  rect(6.2/15 * width, 9.75/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  
  rect(3.5/15 * width, 12.0/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  rect(6.2/15 * width, 12.0/14.5 * height, 2.6/15 * width, 2/14.5 * height, 10);
  
  //--------------- 종목 이름 출력 ----------------//
    textSize(42);
    textAlign(CENTER, CENTER);
    fill(#f6f6e9); 
    text("슈퍼맨", 1.2/15 * width, 2.93/14.5 * height, 2.2/15 * width, 2/14.5 * height);  
    fill(#f6f6e9); 
    text("잽", 1.2/15 * width, 5.18/14.5 * height, 2.2/15 * width, 2/14.5 * height);
    fill(#f6f6e9); 
    text("비틀어 당기기", 1.2/15 * width, 7.43/14.5 * height, 2.2/15 * width, 2/14.5 * height);
    fill(#f6f6e9); 
    text("팔 펴기", 1.2/15 * width, 9.70/14.5 * height, 2.2/15 * width, 2/14.5 * height);
    fill(#f6f6e9); 
    text("팔 올리기", 1.2/15 * width, 11.93/14.5 * height, 2.2/15 * width, 2/14.5 * height);
    
  //--------------- 점수 출력 --------------//
  //sportSelect(rnd);
    textSize(58);
    textAlign(CENTER, CENTER);
    fill(#FBCB4C); 
    text(Integer.toString(arr[0]),          3.5/15 * width, 3.0/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[1]),          6.2/15 * width, 3.0/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[2]),          3.5/15 * width, 5.25/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[3]),          6.2/15 * width, 5.25/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[4] + arr[5]),   3.5/15 * width, 7.5/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[6] + arr[7]),   6.2/15 * width, 7.5/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[8]),          3.5/15 * width, 9.75/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[9]),          6.2/15 * width, 9.75/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[10] + arr[11]), 3.5/15 * width, 12.0/14.5 * height, 2.6/15 * width, 2/14.5 * height);
    fill(#FBCB4C); 
    text(Integer.toString(arr[12] + arr[13]), 6.2/15 * width, 12.0/14.5 * height, 2.6/15 * width, 2/14.5 * height);    
  
  //===== 개인 점수 창 =====//
  fill(#005792);
  rect(9.3/15 * width, 3.0/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10); 
  noFill();
  rect(10.66/15 * width, 3.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 3.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  fill(#005792);
  rect(9.3/15 * width, 4.05/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10); 
  noFill();
  rect(10.66/15 * width, 4.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 4.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);

  fill(#005792);
  rect(9.3/15 * width, 5.25/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10); 
  noFill();
  rect(10.66/15 * width, 5.25/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 5.25/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  fill(#005792);
  rect(9.3/15 * width, 6.30/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10); 
  noFill();
  rect(10.66/15 * width, 6.30/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 6.30/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);

  fill(#005792);
  rect(9.3/15 * width, 7.50/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);
  noFill();
  rect(10.66/15 * width, 7.50/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 7.50/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);

  fill(#005792);
  rect(9.3/15 * width, 8.55/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);  
  noFill();
  rect(10.66/15 * width, 8.55/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 8.55/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);

  fill(#005792);
  rect(9.3/15 * width, 9.75/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);
  noFill();
  rect(10.66/15 * width, 9.75/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 9.75/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  fill(#005792);
  rect(9.3/15 * width, 10.80/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);  
  noFill();
  rect(10.66/15 * width, 10.80/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 10.80/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  fill(#005792);
  rect(9.3/15 * width, 12.0/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);  
  noFill();
  rect(10.66/15 * width, 12.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 12.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  fill(#005792);
  rect(9.3/15 * width, 13.05/14.5 * height, 1.36/15 * width, 0.95/14.5 * height, 10, 0, 0, 10);
  noFill();
  rect(10.66/15 * width, 13.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  rect(12.47/15 * width, 13.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height, 0, 10, 10, 0);
  
  //---------------사람 이름 출력 ----------------//
    textSize(30);
    textAlign(CENTER, CENTER); int m = n - 1;
    fill(#f6f6e9); text(name[0 + 2*(m%4)], 9.3/15 * width, 3.0/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);  
    fill(#f6f6e9); text(name[1 + 2*(m%4)], 9.3/15 * width, 4.05/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[8 + 2*(m%4)], 9.3/15 * width, 5.25/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[9 + 2*(m%4)], 9.3/15 * width, 6.30/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[16 + 2*(m%4)], 9.3/15 * width, 7.50/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[17 + 2*(m%4)], 9.3/15 * width, 8.55/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[24 + 2*(m%4)], 9.3/15 * width, 9.75/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[25 + 2*(m%4)], 9.3/15 * width, 10.80/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[32 + 2*(m%4)], 9.3/15 * width, 12.0/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(name[33 + 2*(m%4)], 9.3/15 * width, 13.05/14.5 * height, 1.36/15 * width, 0.95/14.5 * height);
    
  //--------------- 개인 점수(당일) 출력 ---------------//
    fill(#f6f6e9); text(Integer.toString(score[0]), 10.66/15 * width, 3.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[1]), 10.66/15 * width, 4.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[2]), 10.66/15 * width, 5.25/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[3]), 10.66/15 * width, 6.30/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[4]), 10.66/15 * width, 7.50/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[5]), 10.66/15 * width, 8.55/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[6]), 10.66/15 * width, 9.75/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[7]), 10.66/15 * width, 10.80/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[8]), 10.66/15 * width, 12.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(score[9]), 10.66/15 * width, 13.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    
    //--------------- 개인 점수(총합) 출력---------------//
    fill(#f6f6e9); text(Integer.toString(totscore[0 + 2*(m%4)]), 12.47/15 * width, 3.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[1 + 2*(m%4)]), 12.47/15 * width, 4.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[8 + 2*(m%4)]), 12.47/15 * width, 5.25/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[9 + 2*(m%4)]), 12.47/15 * width, 6.30/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[16 + 2*(m%4)]), 12.47/15 * width, 7.50/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[17 + 2*(m%4)]), 12.47/15 * width, 8.55/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[24 + 2*(m%4)]), 12.47/15 * width, 9.75/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[25 + 2*(m%4)]), 12.47/15 * width, 10.80/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[32 + 2*(m%4)]), 12.47/15 * width, 12.0/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
    fill(#f6f6e9); text(Integer.toString(totscore[33 + 2*(m%4)]), 12.47/15 * width, 13.05/14.5 * height, 1.81/15 * width, 0.95/14.5 * height);
  
  stroke(#f6f6e9);

}
