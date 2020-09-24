# Turn a VAN ID into a URL for FOs to reference
# Example: https://www.votebuilder.com/ContactsDetails.aspx?Vanid=EID5249D66L

import pandas as pd
import civis

client = civis.APIClient()
me = client.users.list_me()

def van_string(vanid):
    vanid = int(vanid)
    q_entry = 'ABCDEFGHIJKLMNOPQ'
    end = q_entry[vanid % 17]
    start = hex(vanid)[2:].upper()[::-1]
    return start + end


def id_to_url(vanid):
    return 'https://www.votebuilder.com/ContactsDetails.aspx?Vanid=EID' + van_string(vanid)
    

def main():
    df = civis.io.read_civis(table='sandbox_va_2.va02_event_p_currstat', 
                             database='DigiDems',
                             use_pandas=True)
    print(df.head())
    
    df['myc_url'] = df['vanid'].apply(lambda vanid: id_to_url(vanid))
    df.sort_values('date', inplace=True)
    
    civis.io.dataframe_to_civis(df, database='DigiDems', table='sandbox_va_2.va02_event_p_url',
                                existing_table_rows='truncate')

main()