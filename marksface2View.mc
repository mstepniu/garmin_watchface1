import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.UserProfile;
import Toybox.WatchUi;
import Toybox.Weather;


class marksface2View extends WatchUi.WatchFace {
    var myBmp, batt1, batt2, batt3, batt4, batt5;
    var base_width;
    var bmpHeart;
    var bmpForecast;
    var forecast_offset;
    var time_offset;
    var bmpAlarm;
    var modifier;

    var day_dict = {"Sat" => Graphics.COLOR_LT_GRAY,
                    "Sun" => Graphics.COLOR_LT_GRAY };

    function initialize() {
        WatchFace.initialize();
        batt1 = WatchUi.loadResource(Rez.Drawables.battery1);
        batt2 = WatchUi.loadResource(Rez.Drawables.battery2);
        batt3 = WatchUi.loadResource(Rez.Drawables.battery3);
        batt4 = WatchUi.loadResource(Rez.Drawables.battery4);
        batt5 = WatchUi.loadResource(Rez.Drawables.battery5);
        bmpHeart = WatchUi.loadResource(Rez.Drawables.heart);
        bmpAlarm = WatchUi.loadResource(Rez.Drawables.alarm);
        base_width = 240;
        
        
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        base_width = dc.getWidth();
        modifier = dc.getWidth() / 240;
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
        setCurrentTime();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        modifier = dc.getHeight() / 240.0;

        setCurrentDate();
        if (Toybox has :Weather) {
            setWeather();
            setForecast();
        }
        else {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.sun);
            forecast_offset = 0;
        }
        
        setStepCountDisplay();
        setCurrentTime();
        setCurrentBatteryLevel();
        setHeartRateDisplay();
        
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        // Place the battery, heart, and forecast bitmaps on top of the layout (after update)
        dc.drawBitmap(dc.getWidth()/2-13, 203 * modifier, myBmp);
        dc.drawBitmap(dc.getWidth()/4-12, 147 * modifier - 3, bmpHeart);
        dc.drawBitmap(dc.getWidth()*3/4-12+forecast_offset, 140 * modifier - 3, bmpForecast);
        var mySettings = System.getDeviceSettings();

        // if there are alarms, then draw the alarm icon above the 'seconds' timer.
        if (mySettings.alarmCount > 0) {
            dc.drawBitmap(195 * modifier, 55 * modifier, bmpAlarm);
        }
        
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
        setCurrentTime();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    }


// CUSTOM FUNCTIONS START -------->>>>>>>>>>   
// CUSTOM FUNCTIONS START -------->>>>>>>>>>   
// CUSTOM FUNCTIONS START -------->>>>>>>>>>   
// CUSTOM FUNCTIONS START -------->>>>>>>>>>   

    // sets the day of the week and month/day at the top
    private function setCurrentDate() {
        var today = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var today_format;
        if (Application.Properties.getValue("Region") == 1){
            today_format = Lang.format(
                "$1$/$2$",
                [
                    today.month,
                    today.day,
                ]
            );
        }
        else {
            today_format = Lang.format(
                "$1$/$2$",
                [
                    today.day,
                    today.month,
                    
                ]
            );
        }

        var date_label = View.findDrawableById("date") as Text;
        date_label.setColor(Application.Properties.getValue("ForegroundColor"));
        date_label.setText(today_format);

        var dayname = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        var day_of_week_format = Lang.format("$1$",[dayname.day_of_week]);

        var day_of_week = View.findDrawableById("dayofweek") as Text;        

        if (day_dict.hasKey(dayname.day_of_week.toString()))
        {
            day_of_week.setColor(Graphics.COLOR_ORANGE);
        }
        else
        {
            day_of_week.setColor(Graphics.COLOR_GREEN);
        }
        day_of_week.setText(day_of_week_format);
    }

    // sets the step counter under the clock time
    private function setStepCountDisplay() {
    	var stepCount = ActivityMonitor.getInfo().steps;
        var stepGoal = ActivityMonitor.getInfo().stepGoal;
	    var stepCountDisplay = View.findDrawableById("StepCountDisplay") as Text;
        if (stepCount >= stepGoal) {
            stepCountDisplay.setColor(Graphics.COLOR_GREEN);
        }
        else {
            stepCountDisplay.setColor(Application.Properties.getValue("ForegroundColor"));
        }
	    stepCountDisplay.setText(stepCount.toString());

        // var view = View.findDrawableById("TimeLabel") as Text;
        // view.setText(timeString);

    }

    private function setCurrentTime() {
        // Get the current time and format it correctly
        var timeFormat = "$1$:$2$";
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var seconds = clockTime.sec.format("%02d");
        var ampm = "am";
        
        if (!System.getDeviceSettings().is24Hour) {
            if (hours > 12) {
                hours = hours - 12;
                ampm = "pm";
            }
            else if (hours == 0) {
                hours = 12;
            }
        } 
        else {
                //timeFormat = "$1$:$2$";
                hours = hours.format("%02d");
                ampm = "";
        }

        var timeString = Lang.format(timeFormat, [hours, clockTime.min.format("%02d")]);
        

        // Update the Clock view
        var view = View.findDrawableById("TimeLabel") as Text;        
        view.setColor(Application.Properties.getValue("ForegroundColor"));
        if (base_width < 240) {
            view.setFont(Graphics.FONT_SYSTEM_NUMBER_MEDIUM);
        }
        view.setText(timeString);

        // Change location offset of the time to depending on how long it is.  11:11 vs 1:11 to keep it centered
        if (hours.toString().length() == 1) {
            time_offset = 10;
        }
        else {
            time_offset = 0;
        }
        view.setLocation((183 * modifier)-time_offset, 60 * modifier);
               

        // Update the Seconds View
        var vseconds = View.findDrawableById("seconds") as Text;

        vseconds.setText(seconds.toString());
        vseconds.setColor(Application.Properties.getValue("ForegroundColor"));
        vseconds.setLocation((195 * modifier)-time_offset, 75 * modifier);

        // Update the AM/PM View
        var vampm = View.findDrawableById("ampm") as Text;
        vampm.setColor(Application.Properties.getValue("ForegroundColor"));
        vampm.setText(ampm);
        vampm.setLocation((195 * modifier)-time_offset, 95 * modifier);

    }

    //sets the battery percentage
    private function setCurrentBatteryLevel() {
        var statsString = System.getSystemStats();
        var test = View.findDrawableById("SystemStats") as Text;
        var current_battery = statsString.battery;
        if (current_battery >= 90)
        {
            myBmp = batt5;
            test.setColor(Application.Properties.getValue("Battery5") as Number);
        }
        else if (current_battery < 90 and current_battery >= 60)
        {
            myBmp = batt4;
            test.setColor(Application.Properties.getValue("Battery4") as Number);
        }
        else if (current_battery < 60 and current_battery >= 35)
        {
            myBmp = batt3;
            test.setColor(Application.Properties.getValue("Battery3") as Number);
        }
        else if (current_battery < 35 and current_battery >= 10)
        {
            myBmp = batt2;
            test.setColor(Application.Properties.getValue("Battery2") as Number);
        }
        else
        {
            myBmp = batt1;
            test.setColor(Application.Properties.getValue("Battery1") as Number);
        }

        var formatted_battery = current_battery.toNumber();

        test.setText(formatted_battery.toString() + "%");
    }


    // sets the Heart Rate
    private function setHeartRateDisplay() {
        // var HRH = ActivityMonitor.getHeartRateHistory(1, true);
        // var HRS = HRH.next();

        var HRT = "";

        if (ActivityMonitor has :getheartRateHistory) {
            HRT = Activity.getActivityInfo().currentHeartRate;
        }
        else {
            var HR_Iterator = ActivityMonitor.getHeartRateHistory(1, true);
            var current_HR = HR_Iterator.next().heartRate;
            if (current_HR != ActivityMonitor.INVALID_HR_SAMPLE) {
                HRT = current_HR.format("%d");
            }
        }

        var lblHeart = View.findDrawableById("heartrate") as Text;
        if (base_width < 240) {
            lblHeart.setFont(Graphics.FONT_SYSTEM_TINY);
        }
        lblHeart.setText(HRT.toString());
    }

    // sets the Temperature, converts to fahrenheit
    private function setWeather() {
        var vdegrees = View.findDrawableById("weather") as Text;
        var Current_Conditions = Weather.getCurrentConditions();

        if (Current_Conditions == null) {
            vdegrees.setText("N\\A");
            return;
        }
        var degrees = Weather.getCurrentConditions().feelsLikeTemperature;
        if (base_width < 210) {
            vdegrees.setFont(Graphics.FONT_SYSTEM_TINY);
        }
        
        if (degrees == null) {
            vdegrees.setText("N\\A");
        }
        else {
            if (Application.Properties.getValue("Temperature") == 1){
                degrees = (degrees * 1.8 + 32.0);
                if (degrees < 60) {
                    vdegrees.setColor(Graphics.COLOR_BLUE);
                }
                else if (degrees >= 60 and degrees < 90) {
                    vdegrees.setColor(Graphics.COLOR_YELLOW);
                }
                else {
                    vdegrees.setColor(Graphics.COLOR_RED);
                }
                
            }
            else {
                if (degrees < 15) {
                    vdegrees.setColor(Graphics.COLOR_BLUE);
                }
                else if (degrees >= 15 and degrees < 32) {
                    vdegrees.setColor(Graphics.COLOR_YELLOW);
                }
                else {
                    vdegrees.setColor(Graphics.COLOR_RED);
                }
            }
            // if (base_width > 350) {
            //     vdegrees.setFont(Graphics.FONT_SYSTEM_MEDIUM);
            // }
            vdegrees.setText(degrees.format("%d").toString() + "°");
        }
        


        // testing weather stuff 

        // var weather_location = Weather.getCurrentConditions().observationLocationName;
        // var vomax_label = View.findDrawableById("vomax") as Text;
        // if (weather_location == null) {
        //     weather_location = "huh?";
        // }
        // vomax_label.setText(weather_location.toString());

    }

    // sets the picture for the forecast.  The full list of conditions are here:
    // https://developer.garmin.com/connect-iq/api-docs/Toybox/Weather.html
    private function setForecast() {
        var Current_Conditions = Weather.getCurrentConditions();
        if (Current_Conditions == null) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.sun);
            forecast_offset = 0;
            return;
        }
        var forecast = Weather.getCurrentConditions().condition;
        forecast_offset = 5;
        
        if (forecast == 10) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.hail);
        }
        else if (forecast == 34) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.wintermix);
        }
        else if (forecast == 36) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.squall);
        }
        else if (forecast == 12 || forecast == 6 || forecast == 28 || forecast == 42) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.thunderstorm);
        }
        else if (forecast == 32) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.tornado);
        }
        else if (forecast == 43 || forecast == 46 || forecast == 51 || forecast == 16 || forecast == 17 ||
                 forecast == 48) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.snow);
        }
        else if (forecast == 3 || forecast == 14 || forecast == 15 || forecast == 18 || forecast == 19 ||
                 forecast == 21 || forecast == 25 || forecast == 26 || forecast == 27 || 
                 forecast == 29 || forecast == 31 || forecast == 49 || forecast == 50 || forecast == 51) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.rain);
        }
        else if (forecast == 10) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.hail);
        }
        else if (forecast == 8 || forecast == 9 || forecast == 33 || forecast == 35 || forecast == 37 ||
                 forecast == 38 || forecast == 39) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.fog);
        }
        else if (forecast == 2 || forecast == 20 || forecast == 45 || forecast == 47 || 
                forecast == 52 || forecast == 53) {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.clouds);
        }
        else {
            bmpForecast = WatchUi.loadResource(Rez.Drawables.sun);
            forecast_offset = 0;

        }

        
        // var vforecast = View.findDrawableById("forecast") as Text;
        
        // vforecast.setText(forecast.toString());

    }

    // gets the max vo2 max between running and cycling and displays it
    // not currently used
    private function setVOMax() {
        // var vVOMax = View.findDrawableById("vomax") as Text;

        // var profile = UserProfile.getProfile();

        // var vomax_cycling = profile.vo2maxCycling;
        // var vomax_running = profile.vo2maxRunning;
        // var final_vomax;
        // if (vomax_cycling == null and vomax_running == null) {
        //     final_vomax = "n/a";
        // }
        // else if (vomax_cycling >= vomax_running) {
        //     final_vomax = vomax_cycling.toString();
        // }
        // else {
        //     final_vomax = vomax_running.toString();
        // }
        
        // vVOMax.setText(final_vomax);
    }

    // this is for the training status, not currently used.
    private function setTrainingStatus() {
        
    }
}