// CS: Odor cue
// US: Water reward regardless of licking

// Pin definition
// portD
#define odorPin0 2 // NO valve that transmit fresh air
#define odorPin1 3 // cue 1
#define odorPin2 4 // cue 2
#define odorPin3 5 // cue 3
#define odorPin4 6 // cue 4
#define odorPin5 7 // final valve

// portB
#define rewardPin 1
#define punishmentPin 0
#define noRewardPin 2
#define sensorPin 4

// Task related variables
int nTrial = 200;
int nCue = 2;
unsigned long valveDuration = 130; // 58 ms -> 3 ul, 72 -> 4, 82 -> 5, 92 -> 6, 102 -> 7, 110 -> 8, 120 -> 9, 130 -> 10
unsigned long duration[5] = {500000,1000000,2500000,82000,5000000};
unsigned long rewardProbability[4] = {100, 0, 100, 0}; // Unit: percent

// state 0: base
// state 1: cue
// state 2: delay
// state 3: reward
// state 4: intertrial interval
// state 9: stand-by
int state = 9;
int select = 0;
int iTrial = 0;
int iReward = 0;
int inivalveDuration = 100;

int cue = 0;
int prevCue = 0;
int nRepeat = 1;
const int maxRepeat = 3;

boolean reward = 0;
boolean outcome = 0;
unsigned long time = 0;
unsigned long timeStart = 0;
boolean prevsensor = false;
boolean cursensor = false;
String inString = "";

// for printf function
int serial_putchar(char c, FILE* f) {
    if (c == '\n') serial_putchar('\r', f);
    return Serial.write(c) == 1? 0 : 1;
}

FILE serial_stdout;

void setup() {
  Serial.begin(115200);
  fdev_setup_stream(&serial_stdout, serial_putchar, NULL, _FDEV_SETUP_WRITE);
  stdout = &serial_stdout;
  randomSeed(analogRead(0));
  
  // Pin setup
  DDRD = B11111110; // Pin 7, 6, 5, 4, 3, 2, 1, 0. Pin 0 and 1 is reserved for serial communication.
  DDRB = B00101111; // Pin xx, xx, 13, 12, 11, 10, 9, 8. 
  PORTD &= B00000011;
  PORTB &= B11010000;
}

// Serial printf output
// b000 : state 0 and trial number
// c1 : state 1 and cue
// r1 : state 2 and reward
// o1 : state 2 and outcome
// i : iti
// l1 : licking
void loop() {
  // Standby state
  if (state==9) {
    if (Serial.available() > 0) {
      select = Serial.read();
      // water valve on
      if (select == 'w') {
        inivalveDuration = Serial.parseInt();
        if (inivalveDuration == 0) {
          inivalveDuration = valveDuration;
        }
        valveOn(inivalveDuration);
      }
      // set trial number
      else if (select == 't') {
        nTrial = Serial.parseInt();
        if (nTrial == 0) {
          nTrial = 200;
        }
      }
      // start trial
      else if (select == 's') {
        int iType = Serial.parseInt();
        if (iType == 0) {
          nCue = 1;
          rewardProbability = {100, 0, 100, 0};
        }
        else if (iType == 1) {
          nCue = 2;
          rewardProbability = {100, 0, 100, 0};
        }
        else if (iType == 2) {
          nCue = 4;
          rewardProbability = {100, 0, 100, 0};
        }
        else if (iType == 3) {
          nCue = 2;
          rewardProbability = {80, 20, 80, 20};
        }
        else if (iType == 4) {
          nCue = 4;
          rewardProbability = {80, 20, 80, 20};
        }
        else {
          nCue = 2;
          nTrial = 200;
          rewardProbability = {100, 0, 100, 0};
        }
        state = 4;
      }
      // number of cues
      else if (select == 'n') {
        nCue = Serial.parseInt();
        if (nCue < 0 || nCue == 3 || nCue > 5) {
          nCue = 2;
        }
        printf("nCue = %d\n",nCue);
      }
    }
  }
  else if (state < 9) {
    
    time = micros();
    
    // Sensor read
    cursensor = bitRead(PINB,sensorPin);
    if (cursensor & ~prevsensor) {
      printf("%lul1\n",time);
      prevsensor = cursensor;
      if (state==2) {
        outcome = true;
      }
    }
    else if (~cursensor & prevsensor) {
      prevsensor = cursensor;
    }
   
    // State conversion if time reaches each duration
    if (time >= timeStart+duration[state]) {
      timeStart = time;
      // state 0: baseline -> 1: cue(0.5 s)
      if (state==0) {
        state = 1;
        PORTD &= B01111111;
        printf("%luc%d\n",time,cue);
      }
      
      // state 1: cue -> state 2: delay (1 s)
      else if (state==1) {
        state = 2;
        PORTD &= B00000011;
        printf("%lud1\n",time);
      }
      
      // state 2: delay (1 s) -> 3: reward
      else if (state==2) { 
        state = 3;
        reward = (random(1,101) <= rewardProbability[cue]);
        printf("%lur%d\n",time,reward);
        if (reward) {
          bitSet(PORTB,rewardPin);
          printf("%luo%d\n",time,++iReward);
        }
        else {
          bitSet(PORTB,noRewardPin);
        }
      }
      
      // state 3: reward -> 4: iti
      else if (state==3) { 
        state = 4;
        PORTB &= B00010000;
        printf("%lui%d\n",time,outcome);
        outcome = false;
        duration[4] = random(4000000,6000001);
      }
      
      // state 4: iti -> 0: base
      else if (state==4) {
        if (iTrial>=nTrial) {
          PORTB &= B00010000;
          state = 9;
          iTrial = 0;
          iReward = 0;
          printf("%lue%d\n",time,state);
        }
        else {
          state = 0;
          ++iTrial;
          
          // if same cue repeates over 3 times, choose difference cue.
          cue = random(nCue);
          if (cue==prevCue) {
            ++nRepeat;
            if (nCue>1 && nRepeat>maxRepeat) {
              cue = 1 - cue;
            }
          }
          else {
            nRepeat = 1;
          }
          prevCue = cue;

          PORTD = B10000100 | (B00001000 << cue);

          printf("%lub%d\n",time,iTrial);
        }
      }
    }
    // State conversion end
   
    
    // Check serial
    if (Serial.available() > 0) {
      select = Serial.read();
      if (select == 'e') {
        nTrial = 0;
      }
    }
  }
}

void valveOn(unsigned long valveDuration)
{
  bitSet(PORTB,rewardPin);
  delay(valveDuration);
  bitClear(PORTB,rewardPin);
}
