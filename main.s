; Archivo: main.S
; Dispositivo: PIC16F887
; Autor: Cristian Catú
; Compilador: pic-as (v.30), MPLABX V5.40
;
; Programa: Contador 4 bits
; Hardware: Botones y timer0
;
; Creado: 15 de feb, 2022
; Última modificación: 15 de feb, 2022

PROCESSOR 16F887
;----------------- bits de configuración --------------------
; CONFIG1
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

; CONFIG2
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)
  // config statements should precede project file includes.
#include <xc.inc>

; ------- VARIABLES EN MEMORIA --------
PSECT udata_shr		    ; Memoria compartida
    W_TEMP:		DS 1
    STATUS_TEMP:	DS 1
    CONTADOR:           DS 1 ;Se establecen variables para el contador
    CONT_PORTC:         DS 1
    CONT_PORTD:         DS 1
  
PSECT resVect, class=CODE, abs, delta=2
; ----------------vector reset-----------------
ORG 00h ;posición 0000h para el reset
resetVec:
    PAGESEL main
    goto main

PSECT intVect, class=CODE, abs, delta=2
ORG 04h			    ; posición 0004h para interrupciones
;-------------- VECTOR INTERRUPCIONES ------------------
PUSH:
    MOVWF   W_TEMP	    ; Guardamos W
    SWAPF   STATUS, W
    MOVWF   STATUS_TEMP	    ; Guardamos STATUS
    
ISR:
    BTFSC RBIF        ; verificamos la bandera de interrupción del puerto B
    CALL INT_IOCB
    BTFSC T0IF        ; verificamos la bandera de interrupción del timer 0
    CALL INT_TMR0

POP:
    SWAPF   STATUS_TEMP, W  
    MOVWF   STATUS	    ; Recuperamos el valor de reg STATUS
    SWAPF   W_TEMP, F	    
    SWAPF   W_TEMP, W	    ; Recuperamos valor de W
    RETFIE		    ; Regresamos a ciclo principal    
; -------------------- subrutinas de interrupción -------------
INT_IOCB: 
    BANKSEL PORTA
    BTFSS PORTB, 0       ; se verifica si se presiona el primer puerto
    INCF PORTA
    BTFSS PORTB, 1       ; se verifica si se presiona el segundo puerto
    DECF PORTA
    BCF RBIF
    RETURN

INT_TMR0:
    MOVF CONTADOR, W        ; se compara el contador con el valor de 50
    XORLW 50
    BTFSC STATUS, 2
    CALL ES_IGUAL
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   178
    MOVWF   TMR0	    ; 20ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    INCF CONTADOR, F        ; se incrementa el contador
    RETURN
    
PSECT code, delta=2, abs
ORG 100h ;posición para el código
tabla:
    CLRF    PCLATH		; Limpiamos registro PCLATH
    BSF	    PCLATH, 0		; Posicionamos el PC en dirección 02xxh
    ANDLW   0x0F		; no saltar más del tamaño de la tabla
    ADDWF   PCL			; Apuntamos el PC a caracter en ASCII de CONT
    RETLW   00111111B			; ASCII char 0
    RETLW   00000110B			; ASCII char 1
    RETLW   01011011B			; ASCII char 2
    RETLW   01001111B			; ASCII char 3
    RETLW   01100110B           	; ASCII char 4
    RETLW   01101101B			; ASCII char 5
    RETLW   01111101B			; ASCII char 6
    RETLW   00000111B			; ASCII char 7
    RETLW   01111111B			; ASCII char 8
    RETLW   01101111B	                ; ASCII char 9
    RETLW   01110111B			; ASCII char 10
    RETLW   01111100B			; ASCII char 11
    RETLW   00111001B			; ASCII char 12
    RETLW   01011110B			; ASCII char 13
    RETLW   01111001B			; ASCII char 14
    RETLW   01110001B			; ASCII char 15
; ---------------- configuración ------------------
main:
    CALL CONFIG_IO
    CALL CONFIG_TMR0
    MOVF PORTB, W
    CALL CONFIG_INT_ENABLE
    CALL CONFIG_RELOJ
;-------------- loop principal ----------------------
LOOP:
    MOVF CONT_PORTD, W
    XORLW 10         ; se compara si el puerto D llegó a 10
    BTFSC STATUS, 2
    CALL ES_10
    MOVF CONT_PORTC, W       
    XORLW 6           ; se compara si el puerto C llegó a 6
    BTFSC STATUS, 2
    CALL ES_6
    GOTO LOOP
;---------------- subrutinas -------------------

CONFIG_IO:
    BANKSEL ANSEL
    CLRF ANSEL
    CLRF ANSELH
    
    BANKSEL TRISA
    BCF TRISA, 0
    BCF TRISA, 1
    BCF TRISA, 2
    BCF TRISA, 3
    CLRF TRISC
    CLRF TRISD
    BSF TRISB, 0
    BSF TRISB, 1
    
    BANKSEL OPTION_REG
    BCF OPTION_REG, 7
    BANKSEL WPUB
    BSF WPUB0
    BSF WPUB1
    
    BANKSEL PORTA
    CLRF PORTA
    MOVLW 00111111B
    MOVWF PORTC
    MOVWF PORTD
    MOVLW 0x00
    MOVWF  CONTADOR
    RETURN
    
CONFIG_INT_ENABLE:
    BSF GIE
    BSF RBIE
    BSF T0IE
    BCF RBIF
    BCF T0IF
    BANKSEL IOCB
    BSF IOCB0
    BSF IOCB1
    RETURN

CONFIG_RELOJ:
    BANKSEL OSCCON	    ; cambiamos a banco 1
    BSF	    OSCCON, 0	    ; SCS -> 1, Usamos reloj interno
    BSF	    OSCCON, 6
    BSF	    OSCCON, 5
    BCF	    OSCCON, 4	    ; IRCF<2:0> -> 110 4MHz
    return

CONFIG_TMR0:
    BANKSEL OPTION_REG	    ; cambiamos de banco
    BCF	    T0CS	    ; TMR0 como temporizador
    BCF	    PSA		    ; prescaler a TMR0
    BSF	    PS2
    BSF	    PS1
    BSF	    PS0		    ; PS<2:0> -> 111 prescaler 1 : 256
    
    BANKSEL TMR0	    ; cambiamos de banco
    MOVLW   178
    MOVWF   TMR0	    ; 50ms retardo
    BCF	    T0IF	    ; limpiamos bandera de interrupción
    return 

ES_IGUAL:                   ; cuando se cuente a 50 se limpia el contador
    CLRF CONTADOR        
    INCF CONT_PORTD, F      ; se incrementa el contador del puerto D
    MOVF CONT_PORTD, W      ; y se va a la tabla para regresar el valor para 7 segmentos
    call tabla
    BANKSEL PORTD
    MOVWF PORTD
    RETURN

ES_10:                   ; cuando se cuente a 10 se resetea el puerto D y se incrementa el puerto C
    CLRF CONT_PORTD
    MOVLW 00111111B
    BANKSEL PORTD
    MOVWF PORTD
    INCF CONT_PORTC, F
    MOVF CONT_PORTC, W
    CALL tabla
    BANKSEL PORTC
    MOVWF PORTC
    RETURN
ES_6:                  ; cuando el puerto C llega a 6 se resetean ambos puertos en los contadores de 7 segmentos
    CLRF CONT_PORTD
    CLRF CONT_PORTC
    MOVLW 00111111B
    BANKSEL PORTD
    MOVWF PORTD
    BANKSEL PORTC
    MOVWF PORTC
    RETURN
    
END