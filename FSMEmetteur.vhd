library ieee;
use ieee.std_logic_1164.all;
entity FSMEmetteur is
	port(
	Bclk, sysclk, rst_b, RTDV, loadRTD: in std_logic;
	DBUS:in std_logic_vector(7 downto 0);
	setRTDV, TxD: out std_logic);
end FSMEmetteur;

architecture rtl of FSMEmetteur is
	type stateType is (IDLE, SYNCH, TDATA);
	signal state, nextstate : stateType;
	signal RDTD : std_logic_vector (8 downto 0); 
	signal RTD : std_logic_vector(7 downto 0); 
	signal Bct: integer range 0 to 9; 
	signal inc, clr, loadRDTD, shftRDTD, start: std_logic;
	signal Bclk_rising, Bclk_dlayed: std_logic;
	
begin
TxD <= RDTD(0);
setRTDV <= loadRDTD;
Bclk_rising <= Bclk and (not Bclk_dlayed); 
Xmit_Control: process(state, RTDV, Bct, Bclk_rising)

begin
inc <= '0'; clr <= '0'; loadRDTD <= '0'; shftRDTD <= '0'; start <= '0';

case state is
when IDLE => 
	if (RTDV = '0' ) then
	loadRDTD <= '1'; nextstate <= SYNCH;
	else nextstate <= IDLE; 
end if;
when SYNCH =>
	if (Bclk_rising = '1') then
	start <= '1'; nextstate <= TDATA;
	else nextstate <= SYNCH; 
	end if;
when TDATA =>
	if (Bclk_rising = '0') then nextstate <= TDATA;
	elsif (Bct /= 9) then
	shftRDTD <= '1'; inc <= '1'; nextstate <= TDATA;
	else clr <= '1'; nextstate <= IDLE; 
	end if;
end case;
end process;
Xmit_update: process (sysclk, rst_b)

begin
	if (rst_b = '0') then
	RDTD <= "111111111"; state <= IDLE; Bct <= 0; Bclk_dlayed <= '0';
	elsif (sysclk'event and sysclk = '1') then
	state <= nextstate;
		if (clr = '1') then Bct <= 0; elsif (inc = '1') then
		Bct <= Bct + 1; 
		end if;
		if (loadRTD = '1') then RTD <= DBUS; 
		end if;
		if (loadRDTD = '1') then RDTD <= RTD & '1'; 
		end if;
		if (start = '1') then RDTD(0) <= '0'; 
		end if;
		if (shftRDTD = '1') then RDTD <= '1' & RDTD(8 downto 1); 
		end if;
	Bclk_dlayed <= Bclk; 
	end if;
end process;
end rtl;