import { get_count, put_count } from "./js_modules/js_functions.js"

let uuid = localStorage.getItem('mango_cv_user_id');

if(uuid === null) {

  let new_id = self.crypto.randomUUID(); //TODO search what this line of code means
  localStorage.setItem('mango_cv_user_id', new_id);

  //TODO change variable aws name to a more appropiate one
  let aws = await get_count();
  aws = Number(aws)+1;
  document.getElementById('aws').innerHTML = aws;
  put_count(aws.toString());

} else {

  let aws = await get_count();
  document.getElementById('aws').innerHTML = aws;

}