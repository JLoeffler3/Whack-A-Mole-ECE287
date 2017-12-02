library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.math_real.all;

entity FPGA_Console is
Port ( 

	clk : in std_logic;
	
--***************************VGA OUTS***************************
	clock_vga : out std_logic;
	hsync1, vsync1 : out std_logic;
	VGA_R,VGA_G,VGA_B : out std_logic_vector(7 downto 0);
--***************************VGA OUTS***************************

--***************************BOARD I/O***************************
	btn1, btn2, btn3, btn4, sw, sw1, sw2, sw3 : in std_logic;
	segCount1 : out std_logic_vector(6 downto 0);
	segCount10 : out std_logic_vector(6 downto 0);
	segCount100 : out std_logic_vector(6 downto 0);
	segCount1000 : out std_logic_vector(6 downto 0);
	led1, led2, led3, led4 : out std_logic);
--***************************BOARD OUTS***************************

end FPGA_Console;

architecture Behavioral of FPGA_Console is
--***************************COMPONENTS***************************
	component lfsr
		port(clk1 : in std_logic;
			  cout : out std_logic_vector(7 downto 0));
	end component;
	component seg
		port(BITS : in std_LOGIC_vector(3 downto 0);
			  A, B, C, D, E, F, G : out std_logic);
	end component;
	component vga_driver
		port(CLK : in std_logic;
			  RST : in std_logic;
			  MLE1 : in std_logic;
			  MLE2 : in std_logic;
			  MLE3 : in std_logic;
			  MLE4 : in std_logic;
			  MODE : in std_logic_vector(2 downto 0);
			  HSYNC : out std_logic;
			  VSYNC : out std_logic;
			  R : out std_logic_vector(7 downto 0);
			  G : out std_logic_vector(7 downto 0);
			  B : out std_logic_vector(7 downto 0);
			  VGA_CLOCK : out std_logic
			  );
	end component;
--***************************COMPONENTS***************************

--***************************SIGNALS***************************
	
	signal modeSelect : std_logic_vector(2 downto 0) := "000";
	signal modeDummy : std_logic;
	
	signal count1, count2, nextMole : integer := 0;
	signal mole1, mole2, mole3, mole4, toIncrease : std_logic ;
	
	signal MUN1, MUN10, MUN100, MUN1000 : std_LOGIC_vector(3 downto 0);
	signal randomnum : std_logic_vector(7 downto 0);
--***************************SIGNALS***************************

--***************************FUNCTIONS***************************
	
	
--***************************FUNCTIONS***************************
	begin
--***************************PORT MAPS***************************
	vga: vga_driver
		port map(
			CLK => clk,
			RST => sw,
			HSYNC => hsync1,
			VSYNC => vsync1,
			VGA_CLOCK => clock_vga,
			MLE1 => mole4,
			MLE2 => mole3,
			MLE3 => mole2,
			MLE4 => mole1,
			MODE => modeSelect,
			R => VGA_R,
			G => VGA_G,
			B => VGA_B
		);
	--***************************SEVEN SEGMENT MAPS***************************
	seg1000: seg
		port map(
			BITS => MUN1000,
			A => segCount1000(0),
			B => segCount1000(1),
			C => segCount1000(2),
			D => segCount1000(3),
			E => segCount1000(4),
			F => segCount1000(5),
			G => segCount1000(6)
		);
	seg100: seg
		port map(
			BITS => MUN100,
			A => segCount100(0),
			B => segCount100(1),
			C => segCount100(2),
			D => segCount100(3),
			E => segCount100(4),
			F => segCount100(5),
			G => segCount100(6)
		);
		seg10: seg
		port map(
			BITS => MUN10,
			A => segCount10(0),
			B => segCount10(1),
			C => segCount10(2),
			D => segCount10(3),
			E => segCount10(4),
			F => segCount10(5),
			G => segCount10(6)
		);
		seg1: seg
		port map(
			BITS => MUN1,
			A => segCount1(0),
			B => segCount1(1),
			C => segCount1(2),
			D => segCount1(3),
			E => segCount1(4),
			F => segCount1(5),
			G => segCount1(6)
		);
	--***************************SEVEN SEGMENT MAPS***************************
	randomgen: lfsr
		port map(
			clk1 => clk,
			cout => randomnum
		);
--***************************PORT MAPS***************************
	Count : process(clk, modeSelect)
		begin
		if clk'event and clk = '1' and modeSelect = "000" then
			count1 <= count1 + 1;
			if count1 > 1000000 and toIncrease = '1' then
				MUN1 <= MUN1 + 1;
				count1 <= 0;
			end if;
			if MUN1 > "1001" then
				MUN1 <= (others => '0');
				MUN10 <= MUN10 + 1;
			end if;
				
			if MUN10 > "1001" then
				MUN10 <= (others => '0');
				MUN100 <= MUN100 + 1;
			end if;
			
			if MUN100 > "1001" then
				MUN100 <= (others => '0');
				MUN1000 <= MUN1000 + 1;
			end if;
			
			if MUN1000 = "1001" and MUN100 = "1001"  and MUN10 = "1001"  and MUN1 = "1001" then
				MUN1 <= (others => '0');
				MUN10 <= (others => '0');
				MUN100 <= (others => '0');
				MUN1000 <= (others => '0');
			end if;
			
		end if;
	end process Count;
	
	Mole_change : process(clk, modeSelect)
		begin
		if clk'event and clk = '1' and modeSelect = "000" then
			count2 <= count2 + 1;
			if count2 > 50000000 then
				if randomnum(0) = '1' then
					mole1 <= '1';
				else
					mole1 <= '0';
				end if;
				if randomnum(2) = '1' then
					mole2 <= '1';
				else
					mole2 <= '0';
				end if;
				if randomnum(4) = '1' then
					mole3 <= '1';
				else
					mole3 <= '0';
				end if;
				if randomnum(6) = '1' then
					mole4 <= '1';
				else
					mole4 <= '0';
				end if;
				count2 <= 0;
			end if;
			if mole1 = '1' and btn4 = '0' then
				toIncrease <= '1';
				mole1 <= '0';
			elsif mole2 = '1' and btn3 = '0' then
				toIncrease <= '1';
				mole2 <= '0';
			elsif mole3 = '1' and btn2 = '0' then
				toIncrease <= '1';
				mole3 <= '0';
			elsif mole4 = '1' and btn1 = '0' then
				toIncrease <= '1';
				mole4 <= '0';
			else
				toIncrease <= '0';
			end if;
		end if;
	end process Mole_change;
	
	led1 <= mole1;
	led2 <= mole2;
	led3 <= mole3;
	led4 <= mole4;
	
	modeSelect(0) <= sw1;
	modeSelect(1) <= sw2;
	modeSelect(2) <= sw3;
	
end Behavioral;
