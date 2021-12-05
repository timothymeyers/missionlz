# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# Python Script for execution collections of tests to verify integration of components within MLZ
# Structure:
# Each test exists as a function, resulting in a true or false value and a message
# All tests are excuted when the script is executed, if any fail script will return a non-zero exit code
# Additionally will print any messages prior to exiting

import argparse
import socket
import sys

environment_vars = ()
test_vars = ()

def parse_mlz_environment(mlz_deployment, test_deployment):
    """Takes two arguments for the file locations of the json output and populates environment dictionaries with their contents

    Args:
        mlz_deployment (string): The string for the location of the file containing the MLZ deployment variables
        test_deployment (string): The string for the location of the file containing the test deployment variables
    """
    return true

def test_network_internal():
    """This function uses variables from the environmen to create and verify a TCP connection between internal network resources
    returns true if connection succeeds

    """

    #TODO: Grab the interal IP Address needed
    hubVMIpAddress = "192.168.0.1"

    #Establish socket
    internal_test = socket.socket()
    #Connect on port 22
    try:
        internal_test.connect((hubVMIpAddress, 22))
        return true, "Successful internal connection"
    except:
        return false, f"Failed to connect to internal ip address: {hubVMIpAddress}"

def test_network_external():
    """This function attempts to establish a connection to bing
    Returns true if connection fails
    """
    #Establish socket
    external_test = socket.socket()
    #Connect on port 22
    try:
        external_test.connect(("bing.com", 443))
        return false, "Successfully connected to external network resource bing.com, should not be allowed"
    except:
        return true, "Success: Failed to connect to bing.com on port 443."
    return true

def tests():
    """Runs the grouping of all test functions contained in the python script and sets the exit to either 1 or 0 to capture an error
    """
    test_functions = [test_network_external, test_network_internal]
    test_function_results = ()
    # Loop all tests executing them and gathering results
    for test in test_Functions:
        res, msg = test()
        if not res:
            test_function_reuslts.append(msg)

    if len(test_function_results) > 0:
        for msg in test_function_results:
            print(msg, file=sys.stderr)
        exit(1)
    else:
        exit(0)


if __name__ == "__main__":
    tests()
