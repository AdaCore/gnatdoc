
package Package_Excluded_From_Documentation is

   --  This package should not be included in generated doc.
   --  @private

   procedure Procedure_Included_Into_Documentation;

   procedure Function_Included_Into_Documentation;

   procedure Procedure_Excluded_From_Documentation;
   --  @private

   procedure Function_Excluded_From_Documentation;
   --  @private

   C : constant Integer := 1;
   --  @private

   subtype Public_Integer is Integer;

   subtype Private_Integer is Integer;
   --  @private

end Package_Excluded_From_Documentation;
