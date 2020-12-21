//
//  FMNetworkExample.swift
//  FMNetworkExample
//
//  Created by PlugN on 21.12.20..
//

import Foundation

// We import the FMNetwork module
import FMNetwork

// We import the CoreTelephony module to read the network.connected property
import CoreTelephony

class FMNetworkExample {
    
    static func run_example_current() {
        
        // In this example, we are going to make some basic operations on the current SIM card.
        // Let's load the current SIM card data.
        let current = FMNetwork(type: .current)
        
        // The first thing to do is to verify that the SIM card is active, which means that it is unlocked and currently in use.
        if current.card.active {
            // Now we know the card is active and the data is accurate.
            // Let's print the basic data of the SIM card
            print("The SIM card name is " + current.card.name + ", and has the following MCC/MNC code: " + current.card.mcc + "/" + current.card.mnc)
            
            // We requested the current SIM card, but now we can check whether that SIM card was the physical SIM card or the eSIM
            if current.card.type == .sim {
                print("The current SIM card is a physical SIM!")
            } else if current.card.type == .esim {
                print("The current SIM card is an eSIM!")
            } else {
                print("This SIM card could not be identified!")
            }
            
            // Enough with the SIM card data, time see to which network it is connected!
            // Let's start with the basic data about the connected network
            print("The SIM card is currently connected to " + current.network.name + ", that uses the following MCC/MNC code: " + current.network.mcc + "/" + current.network.mnc)
            
            // Next up, the protocol to which the SIM card is connected
            // For this step, we need to use CoreTelephony constants
            // This is a fancier way to get the right protocol for the right SIM card instead of using the standard not so easy to use CTTelephonyNetworkInfo().serviceSubscriberCellularProviders
            
            if current.network.connected == CTRadioAccessTechnologyLTE {
                print("The SIM card is currently connected to LTE!")
            } else if current.network.connected.isEmpty {
                print("The SIM card is currently NOT connected to the network!")
            } else {
                print("The SIM card is currently connected on another protocol (5G/3G/2G/GPRS...)")
            }
            
            // Finally, we can compare the 2-digit ISO country codes
            // It's best practice to compare the ISO codes instead of the Mobile Country Code (MCC), as they take into account territorial carrier disputes that share the same MCC
            if current.card.land == current.network.land {
                print("The SIM card and the network connected are in the same country, according to the 2-digit ISO code : " + current.card.land)
            } else {
                print("The SIM card and the network connected are not in the same country, according to the 2-digit ISO code : " + current.card.land + " vs " + current.network.land)
            }
        } else {
            // The card is not active and therefore the data provided may not be accurate. It's best to stop there unless you know what you are doing by continuing to read the data of an inactive SIM card.
            print("The current SIM card is currently not in use (locked or not inserted).")
        }
    }
    
    static func run_example_esim_with_fmobile() {
        // Of course, the run_example_current() would work exactly the same way by using the .sim or .esim type, instead it would be quite useless to check the SIM type, as you know what to expect.
        // In this example, we are going to use the FMobile API service to get more data about a SIM card.
        // Let's load the eSIM card data
        let esim = FMNetwork(type: .esim)
        
        // As always, we check that the SIM card is active first
        if esim.card.active {
            // Now we know the eSIM card is active and in use, and therefore the data are accurate.
            // Let's load the complementary data via the FMobile API service. Keep in mind this requires an active Internet connection. You are fully responsible for the mobile data consumed by this function.
            esim.loadFMobileService { (status) in
                // The status variable indicate whether the data retrival was successful or not.
                if status {
                    // First application example: National Roaming detection
                    
                    
                    // The status variable is equal to true, we can continue.
                    // The FMobile API service provides a lot of data, we will not cover them all in the example otherwise it will be too long.
                    // Let's try to see whether this carrier has a National Roaming Agreement first, by checking if disableFMobileCore is equal to false.
                    if esim.fmobile?.disableFMobileCore == false {
                        // The carrier has a national roaming agreement! Now we still need to determine how to detect it. The first step is to see if the carrier has declared its national roaming agreement, and check the chasedmnc property.
                        if esim.fmobile?.nrdec == true {
                            print("The carrier has declared its national roaming agreement, therefore the chasedmnc property should be equal to the mnc property. \(esim.fmobile?.chasedmnc ?? "null")/\(esim.fmobile?.mnc ?? "null").")
                            
                            // This means that you will need to manually identify if the network is the national roaming network or not. Luckily, you have multiple additional values to help you in this task, including hp and nrp (respectively the protocol that is more likely to be the home network and the national roaming network) and nrfemto (the presence of a Femtocell network on the same protocol as the national roaming).
                            if esim.fmobile?.nrfemto == false {
                                //If nefemto is false, you can simply compare network.connected with the nrp property
                                if esim.network.connected == esim.fmobile?.nrp {
                                    // The eSIM is connected on its national roaming network protocol! Do not forget to compare the card.mcc/mnc with the network.mcc/mnc to ensure the eSIM card is not connected on another network, like aboard.
                                    if esim.network.mcc == esim.fmobile?.mcc && esim.network.mnc == esim.fmobile?.chasedmnc {
                                        print("The eSIM is connected on the national roaming network!")
                                    } else {
                                        print("The eSIM is connected on another network (aboard or exceptional national network).")
                                    }
                                } else {
                                    print("The eSIM is not connected on its national roaming network!")
                                }
                            } else {
                                // If nrfemto is true, you will need to do a speedtest on top of that, using the stms property, indicating the maximum speed of the National Roaming network in Mbps.
                                if esim.network.connected == esim.fmobile?.nrp {
                                    // The eSIM is connected on its national roaming network protocol! Do not forget to compare the card.mcc/mnc with the network.mcc/mnc to ensure the eSIM card is not connected on another network, like aboard.
                                    if esim.network.mcc == esim.fmobile?.mcc && esim.network.mnc == esim.fmobile?.chasedmnc {
                                        print("You need to perform a speedtest using the stms \(esim.fmobile?.stms ?? 0.0) reference as your maximum speed for the national roaming network.")
                                    } else {
                                        print("The eSIM is connected on another network (aboard or exceptional national network).")
                                    }
                                } else {
                                    print("The eSIM is not connected on its national roaming network!")
                                }
                            }
                        } else {
                            // The nrdec property is equal to false, which means you can use the standard mcc/mnc to monitor the national roaming directly.
                            if esim.card.mcc == esim.network.mcc && esim.card.mnc != esim.network.mnc {
                                print("The eSIM is connected on the national roaming network!")
                            } else {
                                print("The eSIM is not connected on the national roaming network!")
                            }
                        }
                    } else {
                        print("The carrier has no national roaming agreement, according to the API. You can use the standard card.mcc/card.mnc to monitor the international roaming. (second application example)")
                    }
                    
                    // Second application example: International Roaming
                    // One other of the handful data the FMobile API service provides are the included international destinations for a carrier.
                    // You can check if the eSIM network is currently outside it's home country first
                    if esim.network.land != esim.card.land {
                        // Now you can check if the current country is included for this carrier
                        if esim.fmobile?.countriesData?.contains(esim.network.land) == true {
                            print("eSIM is aboard, country included for Data-only.")
                        } else if esim.fmobile?.countriesVData?.contains(esim.network.land) == true {
                            print("eSIM is aboard, country included for Voice and Data.")
                        } else if esim.fmobile?.countriesVoice?.contains(esim.network.land) == true {
                            print("eSIM is aboard, country included for Voice-only.")
                        } else {
                            print("eSIM is aboard, destination not included.")
                        }
                    } else {
                        print("eSIM is home.")
                    }
                    
                } else {
                    // The status variable is equal to false, something went wrong.
                    print("Something went wrong. Either your Internet connection is down, or the requested eSIM MCC/MNC doesn't exist on the FMobile API service: " + esim.card.mcc + "/" + esim.card.mnc)
                }
            }
        } else {
            // The card is not active and therefore the data provided may not be accurate. It's best to stop there unless you know what you are doing by continuing to read the data of an inactive SIM card.
            print("The eSIM card is currently not in use (locked or not inserted).")
        }
        
    }
    
}
