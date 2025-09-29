
with Main;

package body Application is

   procedure adainit
     with Import, Convention => C, Link_Name => "adainit";

   procedure app_main
     with Export, Convention => C, Link_Name => "app_main";

   --------------
   -- app_main --
   --------------

   procedure app_main is
   begin
      adainit;
      Main;
   end app_main;

end Application;
