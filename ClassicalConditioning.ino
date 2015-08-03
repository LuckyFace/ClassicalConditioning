/* Classical conditioning task with odor stimuli indicating the probability

    // CS: Odor cue
    // US: Water reward regardless of licking

*/

//// Pin definition
    // portD (pin 0-7)
#define odorPin0 2 // Normally-open valve that transmit fresh air
#define odorPin1 3 // cue 1
#define odorPin2 4 // cue 2
#define odorPin3 5 // cue 3
#define odorPin4 6 // cue 4
#define odorPin5 7 // final valve

    // portB (pin 8-13)
#define rewardPin 1
#define punishmentPin 0 // not used for now
#define noRewardPin 2 // used for cheetah notification
#define sensorPin 4 // pin 12

//// Task related variables
int nTrial = 200; // total trial number
int nCue = 2; // cue number (1, 2, 4)
unsigned long valveDuration = 130; // 58 ms -> 3 ul, 72 -> 4, 82 -> 5, 92 -> 6, 102 -> 7, 110 -> 8, 120 -> 9, 130 -> 10
unsigned long duration[5] = {500000,1000000,2500000,130000,5000000}; // epoch duration
unsigned long rewardProbability[4] = {100, 0, 100, 0}; // unit: percent

int state = 9;
    // state 0: base
    // state 1: cue
    // state 2: delay
    // state 3: reward
    // state 4: intertrial interval
    // state 9: stand-by
int select = 0; // serial input (w for water, t for trial number, s for start, e for end...)
int iTrial = 0; // current trial
int inivalveDuration = 100; // water valve open duration
int itiDuration = 5;

int cue = 0; // current cue
int prevCue = 0; // previous cue
int nRepeat = 1; // current repeat number
const int maxRepeat = 3; // maximal repeat number
int addCue = 0;

boolean reward = 0; // reward in current trial
boolean outcome = 0; // did mouse lick during delay period?
unsigned long time = 0; // current time
unsigned long timeStart = 0; // current epoch start time
boolean prevsensor = false; // previous sensor state
boolean cursensor = false; // current sensor state
String inString = "";

// for printf function (do not edit)
int serial_putchar(char c, FILE* f) {
    if (c == '\n') serial_putchar('\r', f);
    return Serial.write(c) == 1? 0 : 1;
}
FILE serial_stdout;
// end of printf function (do not edit)

void setup() {
    Serial.begin(115200); // serial setup
    fdev_setup_stream(&serial_stdout, serial_putchar, NULL, _FDEV_SETUP_WRITE); // printf setup (do not edit)
    stdout = &serial_stdout; // printf setup (do not edit)
    randomSeed(analogRead(0)); // determines seed number of random function
  
    // Pin setup
    DDRD = B11111110; // Pin 7, 6, 5, 4, 3, 2, 1, 0. Pin 0 and 1 is reserved for serial communication.
    DDRB = B00101111; // Pin xx, xx, 13, 12, 11, 10, 9, 8. 
    PORTD &= B00000011; // reset pin 2-7
    PORTB &= B11010000; // reset pin 8-11 and 13 (pin 12 is sensor)
}

//// Serial printf output form
    // b000 : state 0 and trial number
    // c0 : state 1 and current cue
    // d1 : state 2
    // r0 : state 3 and current reward (Y/N)
    // i : state 4 and outcome
    // l1 : licking
    // e9 : trial end

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
            
            // number of cues
            else if (select == 'n') {
                nCue = Serial.parseInt();
                if (nCue < 0 || nCue == 3 || nCue > 5) {
                    nCue = 2;
                }
            }
            
            else if (select == 'i') {
                itiDuration = Serial.parseInt();
                if (itiDuration < 1 || itiDuration > 10) {
                    itiDuration = 5;
                }
                duration[4] = itiDuration * 1000000;
            }
            
            // start trial
            else if (select == 's') {
                // s0: 1 cue with US+ (p=100)
                // s1: 2 cue with US+/US- (p=100/0)
                // s2: 2 (cue 3/4) with US+/US- (p=100/0)
                // s3: 4 cue with US+/US- (p=100/0)
                // s4: 4 cue with probability (P=80/20)
                int iType = Serial.parseInt();
                    if (iType == 0) {
                        nCue = 1;
                        addCue = 0;
                        rewardProbability[0] = 100;
                        
                    }
                    
                    else if (iType == 1) {
                        nCue = 2;
                        addCue = 0;
                        rewardProbability[0] = 100;
                        rewardProbability[1] = 0;
                    }
                    
                    else if (iType == 2) {
                        nCue = 2;
                        addCue = 2;
                        rewardProbability[0] = 100;
                        rewardProbability[1] = 0;
                    }
                    
                    else if (iType == 3) {
                        nCue = 4;
                        addCue = 0;
                        rewardProbability[0] = 100;
                        rewardProbability[1] = 0;
                        rewardProbability[2] = 100;
                        rewardProbability[3] = 0;
                    }
                    
                    else if (iType == 4) {
                        nCue = 4;
                        addCue = 0;
                        rewardProbability[0] = 80;
                        rewardProbability[1] = 20;
                        rewardProbability[2] = 80;
                        rewardProbability[3] = 20;
                    }
                    
                    else {
                        nCue = 2;
                        addCue = 0;
                        nTrial = 200;
                        rewardProbability[0] = 100;
                        rewardProbability[1] = 0;
                        rewardProbability[2] = 100;
                        rewardProbability[3] = 0;
                    }
                state = 4;
            }
        }
    }
    
    // Task state
    else if (state < 9) {
        time = micros();
    
        // Sensor read
        cursensor = bitRead(PINB,sensorPin);
        if (cursensor & ~prevsensor) { // sensor is on
            printf("%lul1\n",time);
            prevsensor = cursensor;
            if (state==2) { // if sensor is touched during delay state, make outcome true. else, it is omitted trial.
                outcome = true;
            }
        }
        else if (~cursensor & prevsensor) { // sensor is off
            prevsensor = cursensor;
        }
       
        // State conversion if time reaches each epoch duration
        if (time >= timeStart+duration[state]) { // is current duration(=time-timeStart) longer than epoch duration?
            timeStart = time; // reset epoch start time
            
            // state 0: baseline -> 1: cue (0.5 s)
            if (state==0) {
                PORTD &= B01111111; // turn off pin 7 (final odor output valve)
                
                state = 1; // state conversion 0 to 1
                printf("%luc%d\n",time,cue);
            }
          
            // state 1: cue -> state 2: delay (1 s)
            else if (state==1) {
                PORTD &= B00000011; // turn off all odor valves
                
                state = 2;
                printf("%lud1\n",time);
            }
          
            // state 2: delay (1 s) -> 3: reward
            else if (state==2) { 
                reward = (random(1,101) <= rewardProbability[cue]); // determine whether reward is given or not
                if (reward) {
                    bitSet(PORTB,rewardPin); // reward valve open
                }
                else {
                    bitSet(PORTB,noRewardPin); // notify if no reward is given
                }
                
                state = 3;
                printf("%lur%d\n",time,reward);
            }
          
            // state 3: reward -> 4: iti
            else if (state==3) { 
                PORTB &= B00010000; // reset pin 8-11 (turn off water valves)
                
                state = 4;
                duration[4] = random(duration[4]-1000000,duration[4]+1000001); // determine iti duration
                printf("%lui%d\n",time,outcome);
                outcome = false;
            }
          
            // state 4: iti -> 0: base
            else if (state==4) {
                if (iTrial>=nTrial) { // if current trial number is reached goal trial number, return to standby state
                    PORTB &= B00010000; // reset water valve
                    PORTD &= B00000011; // reset odor valve
                    
                    state = 9;
                    iTrial = 0;
                    printf("%lue%d\n",time,state);
                }
                else {
                    cue = random(nCue); // choice cue for next trial
                    if (cue==prevCue) {
                        ++nRepeat;
                        if (nCue>1 && nRepeat>maxRepeat) {
                            cue = (nCue - 1) - cue;
                        }
                    } // if same cue repeats over 3 times, choose difference cue.
                    else {
                        nRepeat = 1;
                    }
                    PORTD = B10000100 | (B00001000 << cue); // turn on NO valve, final valve, and cue stimulus valve
                    
                    state = 0;
                    ++iTrial;
                    prevCue = cue;
                    printf("%lub%d\n",time,iTrial);
        }
      }
        } // State conversion end
        
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
