
# Week 02 | Declarative UI & Responsive Design

## Simple Profile

Result

![Simple Profile IP](screenshots/image3.png)
![Simple Profile Ipad](screenshots/image4.png)

## StatefulWidget dan Cupertino Interaction

![Stateful IP light](screenshots/image5.png)
![Stateful IP dark](screenshots/image6.png)

## Layout Experiment

1. Change breakpoint from 700 to other value and observe the change
- Breakpoint 700 in Ipad air ![Breakpoint 700 ipad air](screenshots/image7.png)
- Breakpoint 900 in Ipad air ![Breakpoint 900 ipad air](screenshots/image8.png) when we increase the breakpoint from 700 to 900 on larger display in this example ipad air, it will stay at 1 column for much longer until we change it to much larger display, then it will turn to 2 column, and it will work on reverse if we change the breakpoint smaller

2. Change themeMode to ThemeMode.dark, and to themeMode.system
- ![Darkmode](screenshots/image9.png) 
- ![System](screenshots/image9.png) in this device, since the system is set to dark, so there are no difference between dark and system theme

3. Test your app with different emulator screen size
- Iphone 12 pro size (390x844) ![Stateful IP light](screenshots/image5.png)
- Ipad air (820x1180) ![Stateful IP AIR light](screenshots/image7.png)

4. Add semantics or label that is important in screen reader
- I added semantics label `Togle dark mode` 