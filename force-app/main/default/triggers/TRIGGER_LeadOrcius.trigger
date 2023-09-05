trigger TRIGGER_LeadOrcius on Lead ( before insert ) {
    Map<String, Carrera__c> carreras;
    Lead leadUpdate;
    List <Lead> ListLeadsUpdate;
    Integer conteoLeads = 0;
    
    ListLeadsUpdate = New List<Lead>();
    //Carreras - Hacemos el Query si y solo si los origenes son de facebook
    carreras = New Map<String, Carrera__c>();
    for(Lead leadNew : Trigger.New){
        if( (leadNew.DetOrigen__c == 'Facebook Orgánico' || leadNew.DetOrigen__c == 'Facebook Ads Form' ) && leadNew.OrciusLead__c == TRUE ){
            conteoLeads += 1;
        }
    }
    if( conteoLeads > 0 ) {
        List <Carrera__c> listaCarrera = [SELECT Id, Sistema__c, NombreSistema__c, Escuela__c, Nombre__c
                                          FROM Carrera__c 
                                          WHERE (    RecordTypeId = '012400000001FbQAAU' 
                                                  OR RecordTypeId = '012400000001FbVAAU' 
                                                  OR RecordTypeId = '012400000001FbaAAE' 
                                                  OR RecordTypeId = '012400000001FbfAAE'
                                                  OR RecordTypeId = '012400000001FbkAAE' ) 
                                          AND Escuela__c != ''];
        for(Carrera__c c : listaCarrera){
            carreras.put(c.Escuela__c, c);
        }
    }

    for(Lead leadNew : Trigger.new){
        
        //Se valida que el lead que se va a insertar tiene origenes de Orcius, si los tiene entonces se prosigue con las conversiones.
        if( ( leadNew.DetOrigen__c == 'Facebook Orgánico' || leadNew.DetOrigen__c == 'Facebook Ads Form' ) && leadNew.OrciusLead__c == TRUE ){
            String nombreEmail = '';
             
            //Transformando el número telefónico
            if( leadNew.MobilePhone != null ){
                String auxNum = leadNew.MobilePhone;
                if( auxNum.length() > 10 ){
                    auxNum = auxNum.right(10);
                }
                leadNew.MobilePhone = auxNum;
                system.debug('AuxNum: ' + leadNew.MobilePhone);
            }
            
            //Transformando el nombre////////////////////////////////////////
            if( leadNew.FirstName != '' && leadNew.FirstName != null ){
                leadNew.FirstName = CONTROL_GeneralParaStrings.fixCase( leadNew.FirstName );
                nombreEmail = leadNew.FirstName;
            }
            if( leadNew.LastName != '' && leadNew.LastName != null ){
                leadNew.LastName = CONTROL_GeneralParaStrings.fixCase(leadNew.LastName);
                if(nombreEmail == '' || nombreEmail == null){
                    
                    nombreEmail = leadNew.LastName;
                    List<String> auxApellidos = New List<String>();
                    auxApellidos = leadNew.LastName.split(' ',2);
                    if( auxApellidos.size() > 1 ){
                        leadNew.FirstName = auxApellidos.get(0);
                        leadNew.LastName = auxApellidos.get(1);
                    }
                }else{
                    nombreEmail = nombreEmail +' ' + leadNew.LastName;
                }
            }
            ////////////////////////////////////////////////////////////
            //
            //Verificando la existencia en salesforce usando nombre emails
            nombreEmail = nombreEmail + '-' + leadNew.Email;
            List<Lead> auxLead = [SELECT Id, OrigenPost__c, MobilePhone, UltimaModMS__c FROM Lead WHERE Email =: leadNew.Email AND Ciclo_Academico__c = null AND Estatus_Interesado__c != 'Duplicado' AND Status = 'INTERESADO'];
            system.debug('Nombre email: ' + nombreEmail + ', arreglo de leads' + auxLead);
            
            List<String> auxString = New List<String>();
            Carrera__c escuelaCarrera;
            
            if( leadNew.Texto_programa__c != null && leadNew.Texto_programa__c != '' ){
                //Tomando el número de programa de interes
                auxString = leadNew.Texto_programa__c.split('-');
                
                system.debug(auxString);
                ////////////////////////////////////////////////////////////
            }else{
                leadNew.DetOrigen__c = 'Facebook Orgánico';
                system.debug('Texto programa vacio.');
            }
            
            //Se valida si hay otro interesado igual, si existe se actualiza y no se inserta
            if( auxlead.size() > 0 ){
                leadUpdate = New Lead();
                leadUpdate = auxlead.get(0);
                
                system.debug('Es un lead duplicado ' + leadNew.Id + ', lead actualizado: ' + leadUpdate.id);
                
                if( auxString.size() > 1){
                    
                    leadUpdate.FirstName = leadNew.FirstName;
                    leadUpdate.LastName = leadNew.LastName;
                    
                    escuelaCarrera = New Carrera__c();
                    
                    if( carreras.containsKey(auxString.get(0).replace(' ','')) ){
                        
                        escuelaCarrera = carreras.get( auxString.get(0).replace(' ','') );
                        
                        if( escuelaCarrera.id != null )
                            leadUpdate.Carrera__c = escuelaCarrera.Id;
                        if( escuelaCarrera.Sistema__c != null )
                            leadUpdate.NoSistema__c = escuelaCarrera.Sistema__c;
                        if( escuelaCarrera.NombreSistema__c != null )
                            leadUpdate.Sistema__c = escuelaCarrera.NombreSistema__c;
                        if( escuelaCarrera.Escuela__c != null )
                            leadUpdate.NoPrograma__c = escuelaCarrera.Escuela__c;
                        if( escuelaCarrera.Nombre__c != null )
                            leadUpdate.Programa__c = escuelaCarrera.Nombre__c;
                        
                    }
                    
                    leadUpdate.periodoCampana__c = 'OTOÑO 2020 (INGRESO EN AGOSTO)';
                    leadUpdate.Email = leadNew.Email;
                    leadUpdate.MobilePhone = leadNew.MobilePhone;
                    leadUpdate.UltimaModMS__c = datetime.now();
                    leadUpdate.OrciusLead__c = TRUE;
                    leadUpdate.OrigenPost__c = CONTROL_GeneralParaStrings.agregarCadenaACadenasSeparadaPorPuntoYComa(leadNew.LeadSource + '-' + leadNew.DetOrigen__c,leadUpdate.OrigenPost__c);
                    
                    if( leadUpdate.NoSistema__c == '101' )
                        leadUpdate.periodoCampana__c = 'OTOÑO 2020 (INGRESO EN AGOSTO)';
                    
                    ListLeadsUpdate.add( leadUpdate );
                }else{
                    leadUpdate.OrciusLead__c = TRUE;
                    leadUpdate.UltimaModMS__c = datetime.now();
                    leadUpdate.MobilePhone = leadNew.MobilePhone;
                    leadUpdate.Email = leadNew.Email;
                    leadUpdate.OrigenPost__c = CONTROL_GeneralParaStrings.agregarCadenaACadenasSeparadaPorPuntoYComa(leadNew.LeadSource + '-' + leadNew.DetOrigen__c,leadUpdate.OrigenPost__c);
                    
                    if( leadUpdate.NoSistema__c == '101' )
                        leadUpdate.periodoCampana__c = 'OTOÑO 2020 (INGRESO EN AGOSTO)';
                    
                    ListLeadsUpdate.add( leadUpdate );
                    system.debug('Texto programa no contiene el número de programa y está duplicado.');
                }
                //Al lead de orcius que se esta insertando se le coloca el indicador para que se borre
                leadNew.Texto_Programa__c = 'ELIMINAR - ES UN INTERESADO ORCIUS DUPLICADO';
                leadNew.Estatus_Interesado__c = 'Duplicado';
                
            //No hay lead guardado con el nombre-correo
            }else{
                if( auxString.size() > 1){
                    escuelaCarrera = New Carrera__c();
                    if( carreras.containsKey( auxString.get(0).replace(' ','') ) ){
                        escuelaCarrera = carreras.get( auxString.get(0).replace(' ','') );
                        if( escuelaCarrera.id != null )
                            leadNew.Carrera__c = escuelaCarrera.Id; 
                        if( escuelaCarrera.Sistema__c != null )
                            leadNew.NoSistema__c = escuelaCarrera.Sistema__c;
                        if( escuelaCarrera.NombreSistema__c != null )
                            leadNew.Sistema__c = escuelaCarrera.NombreSistema__c;
                        if( escuelaCarrera.Escuela__c != null )
                            leadNew.NoPrograma__c = escuelaCarrera.Escuela__c;
                        if( escuelaCarrera.Nombre__c != null )
                            leadNew.Programa__c = escuelaCarrera.Nombre__c;
                    }else{ 
                        system.debug('Validar no. de programa');
                        leadNew.Texto_programa__c = 'V-' + leadNew.Texto_programa__c;
                    }
                    if(leadNew.NoSistema__c == '101')
                        leadNew.periodoCampana__c = 'OTOÑO 2020 (INGRESO EN AGOSTO)';
                    
                    leadNew.UltimaModMS__c = datetime.now();
                }else{
                    system.debug('Texto programa no contiene el número de programa.');
                }
            }
            ////////////////////////////////////////////////////////////
        }else{
            system.debug('No tiene origen Orcius, entonces no hago nada');
        }
    }
    if( ListLeadsUpdate.size() > 0 )
        update ListLeadsUpdate; 
}