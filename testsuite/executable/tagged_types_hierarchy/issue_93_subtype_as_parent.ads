
package Issue_93_Subtype_As_Parent is

   type Unconstrained_Parent (Id : Integer) is
     tagged limited null record;

   type Progenitor is limited interface;

   subtype Constrained_Parent is Unconstrained_Parent (1);

   subtype Progenitor_Subtype is Progenitor;

   type Child is new Constrained_Parent and Progenitor_Subtype with null record;

end Issue_93_Subtype_As_Parent;
