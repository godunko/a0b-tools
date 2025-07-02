
pragma Ada_2022;

with A0B.STM32F401.GPIO;
with A0B.STM32F401.GPIO.PIOC;

procedure Main is
   LED   : A0B.STM32F401.GPIO.GPIO_Line
     renames A0B.STM32F401.GPIO.PIOC.PC13;
   Value : Boolean := False;

begin
   --  LED.Initialize_Output;
   LED.Configure_Output;

   loop
      LED.Set (Value);

      delay 1.0;

      Value := not @;
   end loop;
end Main;
