import unittest
from put_item import lambda_handler

#Negative value
event1 = {
    "pathParameters":{
      "n":"-1"
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
        #Test for negative value input
        #A value of 0 is placed as second argument
        #In place for the context paramter used by the lambda function
        self.assertRaises(ValueError, lambda_handler, event1,0)
        #Test for decimal value input
        self.assertRaises(ValueError, lambda_handler, event2,0)