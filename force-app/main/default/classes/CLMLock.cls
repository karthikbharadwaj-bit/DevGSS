global with sharing class CLMLock {
    global Boolean IsLocked { get; set; }

    global Datetime LockDate { get; set; }

    global string Type { get; set; }

    global CLMUser LockOwner { get; set; }

    global string CheckInHref { get; set; }
}