library ieee;
use ieee.std_logic_1164.all;

entity UART is
	port (
		UART_sel, R_W, clk, rst_b, RxD : in std_logic;
	ADDR2: in std_logic_vector(1 downto 0);
	DBUS : inout std_logic_vector(7 downto 0);
	UART_IRQ, TxD : out std_logic);
end UART;

architecture rtl of UART is

component FSMRecepteur
		port(
	RxD, BclkX8, sysclk, rst_b, RRDP: in std_logic;
	RRD: out std_logic_vector(7 downto 0);
	RRDP, setED, setEE: out std_logic);
end component;

component FSMEmetteur
		port(
	Bclk, sysclk, rst_b, RTDV, loadRTD: in std_logic;
	DBUS:in std_logic_vector(7 downto 0);
	setRTDV, TxD: out std_logic);
end component;

signal RDD : std_logic_vector(7 downto 0); 
signal RSC : std_logic_vector(7 downto 0); 
signal RCC : std_logic_vector(7 downto 0); 
signal RTDV, RRDP, ED, EE, PIT, PIR : std_logic;
signal BaudSel : std_logic_vector(2 downto 0);
signal setRTDV, setRRDP, setED, setEE, loadTDR, loadRCC,newTxd : std_logic;
signal clrRRDP, Bclk, BclkX8, UART_Read, UART_Write : std_logic;

begin

Receiver: FSMRecepteur port map(SSCS, BclkX8, clk, rst_b, RRDP, RDD, setRRDP,setED, setEE);
Transmitter: FSMEmetteur port map(Bclk, clk, rst_b, RTDV, loadTDR, DBUS,setRTDV, newTxD);
TxD<=newTxD;

process (clk, rst_b)
begin
if (rst_b = '0') then
RTDV <= '1'; RRDP <= '0'; ED<= '0'; EE <= '0';
PIT <= '0'; PIR <= '0';
elsif (rising_edge(clk)) then
RTDV <= (setRTDV and not RTDV) or (not loadTDR and RTDV);
RRDP <= (setRRDP and not RRDP) or (not clrRRDP and RRDP);
ED <= (setED and not ED) or (not clrRRDP and ED);
EE <= (setEE and not EE) or (not clrRRDP and EE);

	if (loadRCC = '1') then PIT <= DBUS(7); PIR <= DBUS(6);
	BaudSel <= DBUS(2 downto 0);
	end if;
end if;
end process;

UART_IRQ <= '1' when ((PIR = '1' and (RRDP = '1' or ED = '1'))
or (PIT = '1' and RTDV = '1'))
else '0';

RSC <= RTDV & RRDP & "0000" & ED & EE;
RCC <= PIT & PIR & "000" & BaudSel;
UART_Read <= '1' when (UART_sel = '1' and R_W = '0') else '0';
UART_Write <= '1' when (UART_sel = '1' and R_W = '1') else '0';
clrRRDP <= '1' when (UART_Read = '1' and ADDR2 = "00") else '0';
loadTDR <= '1' when (UART_Write = '1' and ADDR2 = "00") else '0';
loadRCC <= '1' when (UART_Write = '1' and ADDR2 = "10") else '0';
DBUS <= "ZZZZZZZZ" when (UART_Read = '0') 
else RDD when (ADDR2 = "00") 
else RSC when (ADDR2 = "01")
else RCC;

end rtl;
