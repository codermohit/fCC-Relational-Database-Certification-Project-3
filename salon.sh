#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=salon -X --no-align --tuples-only -c"

echo -e "\n~~~~~ MY SALON ~~~~~\n"


MAIN_MENU(){
  if [[ $1 ]]
  then
    echo $1
  else
    echo -e "Welcome to My Salon, how can I help you?\n"
  fi

  SALON_MENU=$($PSQL "SELECT * FROM services");
  if [[ -z SALON_MENU ]]
  then
    echo "No services Available"
  else
    echo "$SALON_MENU" | while IFS="|" read SERVICE_ID SERVICE_NAME
    do
      echo "$SERVICE_ID) $SERVICE_NAME"
    done 
  fi

  #get service id
  read  SERVICE_ID_SELECTED
  if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
  then
    #send to main menu
    MAIN_MENU "I could not find that service. What would you like today?"
  else 
    #check if service id exists in db
    SERVICE_AVAILABILITY=$($PSQL "SELECT * FROM services WHERE service_id=$SERVICE_ID_SELECTED")
    
    if [[ -z $SERVICE_AVAILABILITY ]]
    then
      #send to main menu
      MAIN_MENU "I could not find that service. What would you like today?"
    else
      # get the selected service
      SELECTED_SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id=$SERVICE_ID_SELECTED")
      
      #get user's phone number
      echo -e "\nWhat's your phone number?"
      read CUSTOMER_PHONE

      #check if phone number exist by getting customer name
      CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone='$CUSTOMER_PHONE'")
      
      #if not get customer's name
      if [[ -z $CUSTOMER_NAME ]]
      then
        #if exist then get user's service time
        echo -e "\nI don't have a record for that phone number, what's your name?"
        read CUSTOMER_NAME
        #add the customer to the database
        NEW_CUSTOMER_ADDED="$($PSQL "INSERT INTO customers (phone, name) VALUES ('$CUSTOMER_PHONE','$CUSTOMER_NAME')")"
      fi

      #get customer id
      CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")

      #get time for service
      echo -e "\nWhat time would you like your $SELECTED_SERVICE_NAME, $CUSTOMER_NAME?"
      read SERVICE_TIME      
    fi

    #add the appointment
    APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES ($CUSTOMER_ID, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")
    if [[ $APPOINTMENT_RESULT == 'INSERT 0 1' ]]
    then
      echo -e "\nI have put you down for a cut at $SERVICE_TIME, $CUSTOMER_NAME."
    else
      MAIN_MENU "There was an issue while getting you an appointment."
    fi
  fi
}

MAIN_MENU