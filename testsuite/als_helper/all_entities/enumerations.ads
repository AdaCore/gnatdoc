
package Enumerations is

   type Character_Enumeration is
     ('A',  --  Description of 'A'
      'B',  --  Description of 'B'
      'C',  --  Description of 'C'
      'D', 'E',  --  Description of 'D' and 'E'
      'F', 'G', 'H');
   --  Character enumeration type
   --
   --  @enum 'F' Description of 'F'
   --  @enum 'G' Description of 'G'
   --  @enum 'H' Description of 'H'

private

   Instance : constant Character_Enumeration := 'C';

   procedure Dummy;

end Enumerations;
