import unittest
from put_item import lambda_handler

#Negative value
event1 = {
    "pathParameters":{
      "n":"-5"
   }
}

#Decimal value
event2 = {
    "pathParameters":{
      "n":"11.10"
   }
}
class TestPutItem(unittest.TestCase):
    def test_values(self):
        #A value of 0 is placed as second argument in place for the context paramter used by the lambda functions
        #Test for negative value input
        self.assertRaises(ValueError, lambda_handler, event1,0)
        #Test for decimal value input
        self.assertRaises(ValueError, lambda_handler, event2,0)