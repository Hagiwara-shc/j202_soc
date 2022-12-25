#include "defines.h"
#include "serial.h"

#define SERIAL_SCI_NUM 1

#define SH2_J202_SCI0 ((volatile struct sh2_j202_sci *)0xabcd0100)

struct sh2_j202_sci {
  volatile uint8 bg0;  // Baud Rate Generator Div0 (R/W)
  volatile uint8 bg1;  // Baud Rate Generator Div1 (R/W)
  volatile uint8 con;  // (TXF=full_o, RXE=empty_o) (R only)
//    7     6     5     4     3     2     1      0
//  -----------------------------------------------
// |     |     |     |     |     |     | TXF | RXE |
//  -----------------------------------------------
  volatile uint8 data; // TXD(W only)/UARTRXD(R only)
};

uint32 rxdata;

#define SH2_J202_SCI_CON_RXE   (1<<0)
#define SH2_J202_SCI_CON_TXF   (1<<1)

static struct {
  volatile struct sh2_j202_sci *sci;
} regs[SERIAL_SCI_NUM] = {
  { SH2_J202_SCI0 },
};

/* デバイス初期化 */
//==============================
// Set Baud Rate 115200bps @ 50MHz
//------------------------------
//     115200*4=460.8KHz
//     50MHz/460.8KHz=108=9*12
//     (BRG0 + 2) =  9, BRG0= 7
//     (BRG1 + 0) = 12, BRG1=12
int serial_init(int index, int high_speed)
{
  unsigned char dummy;
  volatile struct sh2_j202_sci *sci = regs[index].sci;

  if (high_speed == 1) {
    sci->bg0 = 2;
    sci->bg1 = 2;
  } else {
    sci->bg0 = 7;
    sci->bg1 = 12;
  }

  while(serial_is_recv_enable(index)) dummy = sci->data;
  return 0;
}

/* 送信可能か？ */
int serial_is_send_enable(int index)
{
  volatile struct sh2_j202_sci *sci = regs[index].sci;
  return (!(sci->con & SH2_J202_SCI_CON_TXF));
}

/* １文字送信 */
int serial_send_byte(int index, unsigned char c)
{
  volatile struct sh2_j202_sci *sci = regs[index].sci;

  
  /* 送信可能になるまで待つ */
  while (!serial_is_send_enable(index))
    ;
  sci->data = c;

  return 0;
}

/* 受信可能か？ */
int serial_is_recv_enable(int index)
{
  volatile struct sh2_j202_sci *sci = regs[index].sci;
  return (!(sci->con & SH2_J202_SCI_CON_RXE));
}

/* １文字受信 */
unsigned char serial_recv_byte(int index)
{
  volatile struct sh2_j202_sci *sci = regs[index].sci;
  unsigned char c;

  /* 受信文字が来るまで待つ */
  while (!serial_is_recv_enable(index))
    ;
  c = sci->data;

  return c;
}
