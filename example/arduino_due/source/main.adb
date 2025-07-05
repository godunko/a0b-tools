
pragma Ada_2022;

with A0B.ATSAM3X8E.PIO.PIOB;

procedure Main is
   LED   : A0B.ATSAM3X8E.PIO.ATSAM3X8E_Pin
     renames A0B.ATSAM3X8E.PIO.PIOB.PB27;
   Value : Boolean := False;

begin
   LED.Configure_Output;

   loop
      LED.Set (Value);

      delay 1.0;

      Value := not @;
   end loop;
end Main;
