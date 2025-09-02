import { get_count, put_count } from "./js_modules/js_functions.js"

let uuid = localStorage.getItem('mango_cv_user_id');

if(uuid === null) {

  let new_id = self.crypto.randomUUID();
  localStorage.setItem('mango_cv_user_id', new_id);

  let counter = await get_count();
  counter = Number(counter)+1;
  document.getElementById('counter').innerHTML = counter;
  put_count(counter.toString());

} else {

  let counter = await get_count();
  document.getElementById('counter').innerHTML = counter;

}