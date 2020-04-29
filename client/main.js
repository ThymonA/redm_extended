RegisterNetEvent('rdx:displayLeftNotification')
AddEventHandler('rdx:displayLeftNotification', DisplayLeftNotification)

function DisplayLeftNotification(title, subTitle, iconDict, icon, duration) {
    const struct1 = new DataView(new ArrayBuffer(4 * 4));

    struct1.setInt32(0, duration, true);

    const string1 = CreateVarString(10, "LITERAL_STRING", title);
    const string2 = CreateVarString(10, "LITERAL_STRING", subTitle);

    const struct2 = new DataView(new ArrayBuffer(48));

    struct2.setBigInt64(8, BigInt(string1), true);
    struct2.setBigInt64(16, BigInt(string2), true);
    struct2.setBigInt64(32, BigInt(GetHashKey(iconDict)), true);
    struct2.setBigInt64(40, BigInt(GetHashKey(icon)), true);

    Citizen.invokeNative("0x26E87218390E6729", struct1, struct2, 1, 1);
}

RegisterNetEvent('rdx:displayTopCenterNotification')
AddEventHandler('rdx:displayTopCenterNotification', DisplayTopCenterNotification)

function DisplayTopCenterNotification(text, duration, town) {
    const struct1 = new DataView(new ArrayBuffer(4 * 4));

    struct1.setInt32(0, duration, true);

    const string = CreateVarString(10, "LITERAL_STRING", town);
    const string2 = CreateVarString(10, "LITERAL_STRING", text);
    const struct2 = new DataView(new ArrayBuffer(24));

    struct2.setBigInt64(8, BigInt(string), true);
    struct2.setBigInt64(16, BigInt(string2), true);

    Citizen.invokeNative("0xD05590C1AB38F068", struct1, struct2, 1, 1);
}