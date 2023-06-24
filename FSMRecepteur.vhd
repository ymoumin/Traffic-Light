library ieee;
use ieee.std_logic_1164.all;
entity FSMRecepteur is
	port(
	RxD, BclkX8, sysclk, rst_b, RRDP: in std_logic;
	RRD: out std_logic_vector(7 downto 0);
	RRDP, setED, setEE: out std_logic);
end FSMRecepteur;

architecture rtl of FSMRecepteur is
	type stateType is (IDLE, START_DETECTED, RECV_DATA);
	signal state, nextstate: stateType;
	signal RSR: std_logic_vector (7 downto 0); 
	signal ct1 : integer range 0 to 7; 
	signal ct2 : integer range 0 to 8;
	signal inc1, inc2, clr1, clr2, shftRSR, loadRRD : std_logic;
	signal BclkX8_Dlayed, BclkX8_rising : std_logic;
begin

BclkX8_rising <= BclkX8 and (not BclkX8_Dlayed);

Rcvr_Control: process(state, RxD, RRDP, ct1, ct2, BclkX8_rising)
begin
 
inc1 <= '0'; inc2 <= '0'; clr1 <= '0'; clr2 <= '0';
shftRSR <= '0'; loadRRD <= '0'; setRRDP <= '0'; setED <= '0'; setEE <= '0';
case state is
when IDLE => if (RxD = '0' ) then nextstate <= START_DETECTED;
else nextstate <= IDLE; end if;
when START_DETECTED =>
	if (BclkX8_rising = '0') then nextstate <= START_DETECTED;
	elsif (RxD = '1') then clr1 <= '1'; nextstate <= IDLE;
	elsif (ct1 = 3) then clr1 <= '1'; nextstate <= RECV_DATA;
	else inc1 <= '1'; nextstate <= START_DETECTED; 
	end if;
when RECV_DATA =>
	if (BclkX8_rising = '0') then nextstate <= RECV_DATA;
	else inc1 <= '1';
	if (ct1 /= 7) then nextstate <= RECV_DATA;
	
	elsif (ct2 /= 8) then
	shftRSR <= '1'; inc2 <= '1'; clr1 <= '1'; 
	nextstate <= RECV_DATA;
	else
		nextstate <= IDLE;
		setRRDP <= '1'; clr1 <= '1'; clr2 <= '1';
		if (RRDP = '1') then setED <= '1'; 
		elsif (RxD = '0') then setEE <= '1'; 
		else loadRRD <= '1'; 
		end if; 
	end if;
	end if;
end case;
end process;

Rcvr_update: process (sysclk, rst_b)
begin
if (rst_b = '0') then state <= IDLE; BclkX8_Dlayed <= '0';
ct1 <= 0; ct2 <= 0;
elsif (sysclk'event and sysclk = '1') then
state <= nextstate;
if (clr1 = '1') then ct1 <= 0; elsif (inc1 = '1') then
ct1 <= ct1 + 1; end if;
if (clr2 = '1') then ct2 <= 0; elsif (inc2 = '1') then
ct2 <= ct2 + 1; end if;
if (shftRSR = '1') then RSR <= RxD & RSR(7 downto 1); end if;

if (loadRRD = '1') then RRD <= RSR; end if;
BclkX8_Dlayed <= BclkX8; 
end if;
end process;
end rtl;