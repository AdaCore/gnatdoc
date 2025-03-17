
package Package_Excluded_From_Documentation is

   --  This package doesn't included into generated documentation.
   --  @private

   procedure Procedure_Included_Into_Documentation;

   procedure Function_Included_Into_Documentation;

   procedure Procedure_Excluded_From_Documentation;
   --  @private

   procedure Function_Excluded_From_Documentation;
   --  @private

end Package_Excluded_From_Documentation;

