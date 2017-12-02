library ieee;
    use ieee.std_logic_1164.all;

entity lfsr is
  port (
    cout   :out std_logic_vector (7 downto 0);-- Output of the counter
    clk1    :in  std_logic                    -- Input rlock
  );
end entity;

architecture rtl of lfsr is
    signal count           :std_logic_vector (7 downto 0) := "11010101";
    signal linear_feedback :std_logic;

begin
    
    process (clk1) 
		begin
        if (rising_edge(clk1)) then
				linear_feedback <= (((count(7) xor count(5)) xor count(4)) xor count(3));
				count <= (count(6) & count(5) & count(4) & count(3) 
							  & count(2) & count(1) & count(0) & 
							  linear_feedback);
        end if;
    end process;
    cout <= count;
end architecture;