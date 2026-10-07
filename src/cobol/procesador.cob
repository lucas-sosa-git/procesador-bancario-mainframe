       >>SOURCE FORMAT FREE
identification division.
program-id. BANCO.

environment division.
input-output section.
file-control.
    select cuentas-entrada
        assign to "CUENTAS"
        organization is line sequential
        file status is estado-cuentas-entrada.
    select movimientos-entrada
        assign to "MOVIM"
        organization is line sequential
        file status is estado-movimientos-entrada.
    select cuentas-salida
        assign to "CUENACT"
        organization is line sequential
        file status is estado-cuentas-salida.
    select reporte-cierre
        assign to "CIERRE"
        organization is line sequential
        file status is estado-reporte-cierre.
    select rechazados-salida
        assign to "RECHAZOS"
        organization is line sequential
        file status is estado-rechazados-salida.

data division.
file section.
fd cuentas-entrada
    record is varying in size from 1 to 80 characters
    depending on longitud-cuentas-entrada.
01 registro-cuentas-entrada pic x(80).

fd movimientos-entrada
    record is varying in size from 1 to 80 characters
    depending on longitud-movimientos-entrada.
01 registro-movimientos-entrada pic x(80).

fd cuentas-salida
    record is varying in size from 1 to 80 characters
    depending on longitud-cuentas-salida.
01 registro-cuentas-salida pic x(80).

fd reporte-cierre
    record is varying in size from 1 to 132 characters
    depending on longitud-reporte-cierre.
01 registro-reporte-cierre pic x(132).

fd rechazados-salida
    record is varying in size from 1 to 160 characters
    depending on longitud-rechazados-salida.
01 registro-rechazados-salida pic x(160).

working-storage section.
78 maximo-cuentas value 50000.
78 saldo-maximo-cuenta value 999999999999.99.

01 estado-cuentas-entrada pic xx value spaces.
01 estado-movimientos-entrada pic xx value spaces.
01 estado-cuentas-salida pic xx value spaces.
01 estado-reporte-cierre pic xx value spaces.
01 estado-rechazados-salida pic xx value spaces.

01 longitud-cuentas-entrada pic 9(3) comp value 0.
01 longitud-movimientos-entrada pic 9(3) comp value 0.
01 longitud-cuentas-salida pic 9(3) comp value 0.
01 longitud-reporte-cierre pic 9(3) comp value 0.
01 longitud-rechazados-salida pic 9(3) comp value 0.

01 error-ejecucion pic 9 value 0.
01 mensaje-error pic x(100) value spaces.
01 cantidad-cuentas pic 9(5) comp value 0.
01 tabla-cuentas.
   05 fila-cuenta occurs 50000 times.
      10 id-cuenta pic x(10).
      10 saldo-cuenta pic 9(12)v99 comp-3.

01 cantidad-movimientos pic 9(9) comp-3 value 0.
01 cantidad-aceptados pic 9(9) comp-3 value 0.
01 cantidad-rechazados pic 9(9) comp-3 value 0.
01 cantidad-depositos pic 9(9) comp-3 value 0.
01 cantidad-extracciones pic 9(9) comp-3 value 0.
01 cantidad-transferencias pic 9(9) comp-3 value 0.
01 total-depositos pic 9(15)v99 comp-3 value 0.
01 total-extracciones pic 9(15)v99 comp-3 value 0.
01 total-transferencias pic 9(15)v99 comp-3 value 0.

01 id-movimiento pic x(10) value spaces.
01 tipo-operacion pic x value space.
01 id-cuenta-origen pic x(10) value spaces.
01 id-cuenta-destino pic x(10) value spaces.
01 importe-texto pic x(15) value spaces.
01 importe-valor pic 9(12)v99 comp-3 value 0.
01 importe-valido pic 9 value 0.
01 movimiento-invalido pic 9 value 0.
01 motivo-rechazo pic x(70) value spaces.

01 id-cuenta-busqueda pic x(10) value spaces.
01 cuenta-encontrada pic 9 value 0.
01 indice-cuenta-encontrada pic 9(5) comp value 0.
01 limite-inferior pic 9(5) comp value 0.
01 limite-superior pic 9(5) comp value 0.
01 medio-busqueda pic 9(5) comp value 0.
01 indice-origen pic 9(5) comp value 0.
01 indice-destino pic 9(5) comp value 0.
01 margen-saldo pic 9(12)v99 comp-3 value 0.
01 indice-bucle-cuenta pic 9(5) comp value 0.

01 puntero-reporte pic 9(3) comp value 1.
01 puntero-rechazo pic 9(3) comp value 1.
01 cantidad-formateada pic z(8)9.
01 importe-formateado pic z(14)9.99.
01 saldo-presentacion pic 9(12).99.

procedure division.
procedimiento-principal.
    perform cargar-cuentas
    if error-ejecucion = 0
        perform procesar-movimientos
    end-if
    if error-ejecucion = 0
        perform escribir-cuentas-actualizadas
    end-if
    if error-ejecucion = 0
        perform escribir-reporte-cierre
    end-if
    if error-ejecucion = 1
        move 12 to return-code
    else
        move 0 to return-code
        move cantidad-movimientos to cantidad-formateada
        display "Procesamiento finalizado. Movimientos: "
            function trim(cantidad-formateada) no advancing
        move cantidad-aceptados to cantidad-formateada
        display ", aceptados: " function trim(cantidad-formateada) no advancing
        move cantidad-rechazados to cantidad-formateada
        display ", rechazados: " function trim(cantidad-formateada)
    end-if
    stop run.

cargar-cuentas.
    open input cuentas-entrada
    if estado-cuentas-entrada not = "00"
        move "No se pudo abrir el archivo de cuentas (CUENTAS)."
            to mensaje-error
        display "ESTADO DEL ARCHIVO DE CUENTAS: " estado-cuentas-entrada
        perform detener-con-error
        exit paragraph
    end-if

    perform until estado-cuentas-entrada = "10" or error-ejecucion = 1
        read cuentas-entrada
            at end continue
        end-read
        evaluate estado-cuentas-entrada
            when "00"
                perform validar-y-guardar-cuenta
            when "10"
                continue
            when other
                move "Error de lectura en el archivo de cuentas."
                    to mensaje-error
                perform detener-con-error
        end-evaluate
    end-perform
    close cuentas-entrada.

validar-y-guardar-cuenta.
    if longitud-cuentas-entrada not = 26
        move "Registro de cuenta invalido: longitud debe ser 26."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if
    if registro-cuentas-entrada(11:1) not = "|"
        move "Registro de cuenta invalido: falta separador."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if
    if registro-cuentas-entrada(1:10) is not numeric
        move "Registro de cuenta invalido: ID debe tener 10 digitos."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if

    move registro-cuentas-entrada(12:15) to importe-texto
    perform validar-importe
    if importe-valido = 0
        move "Registro de cuenta invalido: saldo debe ser 12 digitos, punto y 2 digitos."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if

    if cantidad-cuentas >= maximo-cuentas
        move "Se excedio el maximo de 50000 cuentas."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if
    if cantidad-cuentas > 0
        if registro-cuentas-entrada(1:10) <= id-cuenta(cantidad-cuentas)
            move "Las cuentas deben estar ordenadas por ID y no repetirse."
                to mensaje-error
            perform detener-con-error
            exit paragraph
        end-if
    end-if

    add 1 to cantidad-cuentas
    move registro-cuentas-entrada(1:10) to id-cuenta(cantidad-cuentas)
    move importe-valor to saldo-cuenta(cantidad-cuentas).

procesar-movimientos.
    open input movimientos-entrada
    if estado-movimientos-entrada not = "00"
        move "No se pudo abrir el archivo de movimientos (MOVIM)."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if

    open output rechazados-salida
    if estado-rechazados-salida not = "00"
        move "No se pudo crear el archivo de rechazados (RECHAZOS)."
            to mensaje-error
        perform detener-con-error
        close movimientos-entrada
        exit paragraph
    end-if
    move "MOVIMIENTO|MOTIVO" to registro-rechazados-salida
    move 17 to longitud-rechazados-salida
    write registro-rechazados-salida
    if estado-rechazados-salida not = "00"
        move "Error al escribir el encabezado de rechazados."
            to mensaje-error
        perform detener-con-error
    end-if

    perform until estado-movimientos-entrada = "10" or error-ejecucion = 1
        read movimientos-entrada
            at end continue
        end-read
        evaluate estado-movimientos-entrada
            when "00"
                add 1 to cantidad-movimientos
                perform procesar-un-movimiento
            when "10"
                continue
            when other
                move "Error de lectura en el archivo de movimientos."
                    to mensaje-error
                perform detener-con-error
        end-evaluate
    end-perform
    close movimientos-entrada
    close rechazados-salida.

procesar-un-movimiento.
    move 0 to movimiento-invalido
    move spaces to motivo-rechazo id-movimiento tipo-operacion
        id-cuenta-origen id-cuenta-destino importe-texto
    move 0 to importe-valor

    if longitud-movimientos-entrada not = 50
        move "FORMATO INVALIDO: longitud debe ser 50" to motivo-rechazo
        perform marcar-invalido
    else
        if registro-movimientos-entrada(11:1) not = "|"
           or registro-movimientos-entrada(13:1) not = "|"
           or registro-movimientos-entrada(24:1) not = "|"
           or registro-movimientos-entrada(35:1) not = "|"
            move "FORMATO INVALIDO: separadores en posiciones incorrectas"
                to motivo-rechazo
            perform marcar-invalido
        else
            move registro-movimientos-entrada(1:10) to id-movimiento
            move registro-movimientos-entrada(12:1) to tipo-operacion
            move registro-movimientos-entrada(14:10) to id-cuenta-origen
            move registro-movimientos-entrada(25:10) to id-cuenta-destino
            move registro-movimientos-entrada(36:15) to importe-texto
            perform validar-campos-movimiento
        end-if
    end-if

    if movimiento-invalido = 0
        evaluate tipo-operacion
            when "D"
                perform procesar-deposito
            when "E"
                perform procesar-extraccion
            when "T"
                perform procesar-transferencia
        end-evaluate
    end-if

    if movimiento-invalido = 1
        add 1 to cantidad-rechazados
        perform escribir-movimiento-rechazado
    else
        add 1 to cantidad-aceptados
    end-if.

validar-campos-movimiento.
    if id-movimiento is not numeric
        move "ID DE MOVIMIENTO INVALIDO: se requieren 10 digitos"
            to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    if tipo-operacion not = "D" and tipo-operacion not = "E"
       and tipo-operacion not = "T"
        move "TIPO INVALIDO: usar D (deposito), E (extraccion) o T (transferencia)"
            to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    perform validar-importe
    if importe-valido = 0
        move "IMPORTE INVALIDO: usar 12 digitos, punto y 2 digitos"
            to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    if importe-valor = 0
        move "IMPORTE INVALIDO: debe ser mayor que cero"
        to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    evaluate tipo-operacion
        when "D"
            if id-cuenta-origen not = spaces
                move "DEPOSITO INVALIDO: cuenta origen debe quedar vacia"
                    to motivo-rechazo
                perform marcar-invalido
                exit paragraph
            end-if
            if id-cuenta-destino is not numeric
                move "DEPOSITO INVALIDO: falta una cuenta destino numerica"
                    to motivo-rechazo
                perform marcar-invalido
                exit paragraph
            end-if
        when "E"
            if id-cuenta-origen is not numeric
                move "EXTRACCION INVALIDA: falta una cuenta origen numerica"
                    to motivo-rechazo
                perform marcar-invalido
                exit paragraph
            end-if
            if id-cuenta-destino not = spaces
                move "EXTRACCION INVALIDA: cuenta destino debe quedar vacia"
                    to motivo-rechazo
                perform marcar-invalido
                exit paragraph
            end-if
        when "T"
            if id-cuenta-origen is not numeric
               or id-cuenta-destino is not numeric
                move "TRANSFERENCIA INVALIDA: origen y destino son obligatorios"
                    to motivo-rechazo
                perform marcar-invalido
                exit paragraph
            end-if
    end-evaluate.

procesar-deposito.
    move id-cuenta-destino to id-cuenta-busqueda
    perform buscar-cuenta
    if cuenta-encontrada = 0
        move "CUENTA DESTINO INEXISTENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    move indice-cuenta-encontrada to indice-destino
    compute margen-saldo = saldo-maximo-cuenta
        - saldo-cuenta(indice-destino)
    if importe-valor > margen-saldo
        move "SALDO DESTINO EXCEDE EL MAXIMO PERMITIDO" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    add importe-valor to saldo-cuenta(indice-destino)
    add 1 to cantidad-depositos
    add importe-valor to total-depositos.

procesar-extraccion.
    move id-cuenta-origen to id-cuenta-busqueda
    perform buscar-cuenta
    if cuenta-encontrada = 0
        move "CUENTA ORIGEN INEXISTENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    move indice-cuenta-encontrada to indice-origen
    if saldo-cuenta(indice-origen) < importe-valor
        move "SALDO INSUFICIENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    subtract importe-valor from saldo-cuenta(indice-origen)
    add 1 to cantidad-extracciones
    add importe-valor to total-extracciones.

procesar-transferencia.
    if id-cuenta-origen = id-cuenta-destino
        move "TRANSFERENCIA INVALIDA: origen y destino son iguales"
            to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    move id-cuenta-origen to id-cuenta-busqueda
    perform buscar-cuenta
    if cuenta-encontrada = 0
        move "CUENTA ORIGEN INEXISTENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    move indice-cuenta-encontrada to indice-origen

    move id-cuenta-destino to id-cuenta-busqueda
    perform buscar-cuenta
    if cuenta-encontrada = 0
        move "CUENTA DESTINO INEXISTENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    move indice-cuenta-encontrada to indice-destino

    if saldo-cuenta(indice-origen) < importe-valor
        move "SALDO INSUFICIENTE" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if
    compute margen-saldo = saldo-maximo-cuenta
        - saldo-cuenta(indice-destino)
    if importe-valor > margen-saldo
        move "SALDO DESTINO EXCEDE EL MAXIMO PERMITIDO" to motivo-rechazo
        perform marcar-invalido
        exit paragraph
    end-if

    subtract importe-valor from saldo-cuenta(indice-origen)
    add importe-valor to saldo-cuenta(indice-destino)
    add 1 to cantidad-transferencias
    add importe-valor to total-transferencias.

validar-importe.
    move 0 to importe-valido importe-valor
    if importe-texto(1:12) is numeric
       and importe-texto(13:1) = "."
       and importe-texto(14:2) is numeric
        compute importe-valor = function numval(importe-texto)
        move 1 to importe-valido
    end-if.

buscar-cuenta.
    move 0 to cuenta-encontrada indice-cuenta-encontrada
    move 1 to limite-inferior
    move cantidad-cuentas to limite-superior
    perform until limite-inferior > limite-superior or cuenta-encontrada = 1
        compute medio-busqueda rounded = (limite-inferior + limite-superior) / 2
        if id-cuenta(medio-busqueda) = id-cuenta-busqueda
            move 1 to cuenta-encontrada
            move medio-busqueda to indice-cuenta-encontrada
        else
            if id-cuenta(medio-busqueda) < id-cuenta-busqueda
                compute limite-inferior = medio-busqueda + 1
            else
                compute limite-superior = medio-busqueda - 1
            end-if
        end-if
    end-perform.

marcar-invalido.
    move 1 to movimiento-invalido.

escribir-movimiento-rechazado.
    move spaces to registro-rechazados-salida
    move 1 to puntero-rechazo
    if longitud-movimientos-entrada > 0
        string registro-movimientos-entrada(1:longitud-movimientos-entrada)
            delimited by size
            "|" delimited by size
            function trim(motivo-rechazo) delimited by size
            into registro-rechazados-salida
            with pointer puntero-rechazo
        end-string
    else
        string "|" delimited by size
            function trim(motivo-rechazo) delimited by size
            into registro-rechazados-salida
            with pointer puntero-rechazo
        end-string
    end-if
    compute longitud-rechazados-salida = puntero-rechazo - 1
    write registro-rechazados-salida
    if estado-rechazados-salida not = "00"
        move "Error al escribir un movimiento rechazado."
            to mensaje-error
        perform detener-con-error
    end-if.

escribir-cuentas-actualizadas.
    open output cuentas-salida
    if estado-cuentas-salida not = "00"
        move "No se pudo crear el archivo de cuentas actualizado (CUENACT)."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if

    perform varying indice-bucle-cuenta from 1 by 1
        until indice-bucle-cuenta > cantidad-cuentas or error-ejecucion = 1
        move spaces to registro-cuentas-salida
        move id-cuenta(indice-bucle-cuenta)
            to registro-cuentas-salida(1:10)
        move "|" to registro-cuentas-salida(11:1)
        move saldo-cuenta(indice-bucle-cuenta)
            to saldo-presentacion
        move saldo-presentacion to registro-cuentas-salida(12:15)
        move 26 to longitud-cuentas-salida
        write registro-cuentas-salida
        if estado-cuentas-salida not = "00"
            move "Error al escribir el archivo de cuentas actualizado."
                to mensaje-error
            perform detener-con-error
        end-if
    end-perform
    close cuentas-salida.

escribir-reporte-cierre.
    open output reporte-cierre
    if estado-reporte-cierre not = "00"
        move "No se pudo crear el reporte de cierre (CIERRE)."
            to mensaje-error
        perform detener-con-error
        exit paragraph
    end-if

    move "REPORTE DE CIERRE - PROCESADOR BANCARIO" to registro-reporte-cierre
    move 39 to longitud-reporte-cierre
    perform escribir-registro-cierre
    move "----------------------------------------" to registro-reporte-cierre
    move 40 to longitud-reporte-cierre
    perform escribir-registro-cierre

    move cantidad-movimientos to cantidad-formateada
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Movimientos leidos: " delimited by size
        function trim(cantidad-formateada) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-aceptados to cantidad-formateada
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Operaciones aceptadas: " delimited by size
        function trim(cantidad-formateada) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-rechazados to cantidad-formateada
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Operaciones rechazadas: " delimited by size
        function trim(cantidad-formateada) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-cuentas to cantidad-formateada
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Cuentas procesadas: " delimited by size
        function trim(cantidad-formateada) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-depositos to cantidad-formateada
    move total-depositos to importe-formateado
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Depositos aceptados: " delimited by size
        function trim(cantidad-formateada) delimited by size
        " | importe: " delimited by size
        function trim(importe-formateado) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-extracciones to cantidad-formateada
    move total-extracciones to importe-formateado
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Extracciones aceptadas: " delimited by size
        function trim(cantidad-formateada) delimited by size
        " | importe: " delimited by size
        function trim(importe-formateado) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move cantidad-transferencias to cantidad-formateada
    move total-transferencias to importe-formateado
    move spaces to registro-reporte-cierre
    move 1 to puntero-reporte
    string "Transferencias aceptadas: " delimited by size
        function trim(cantidad-formateada) delimited by size
        " | importe: " delimited by size
        function trim(importe-formateado) delimited by size
        into registro-reporte-cierre with pointer puntero-reporte
    end-string
    perform escribir-linea-reporte

    move "SALDOS DE CIERRE (CUENTA|SALDO)" to registro-reporte-cierre
    move 31 to longitud-reporte-cierre
    perform escribir-registro-cierre

    perform varying indice-bucle-cuenta from 1 by 1
        until indice-bucle-cuenta > cantidad-cuentas or error-ejecucion = 1
        move saldo-cuenta(indice-bucle-cuenta)
            to saldo-presentacion
        move spaces to registro-reporte-cierre
        move 1 to puntero-reporte
        string id-cuenta(indice-bucle-cuenta) delimited by size
            "|" delimited by size
            saldo-presentacion delimited by size
            into registro-reporte-cierre with pointer puntero-reporte
        end-string
        perform escribir-linea-reporte
    end-perform
    close reporte-cierre.

escribir-linea-reporte.
    compute longitud-reporte-cierre = puntero-reporte - 1
    perform escribir-registro-cierre.

escribir-registro-cierre.
    if error-ejecucion = 0
        write registro-reporte-cierre
        if estado-reporte-cierre not = "00"
            move "Error al escribir el reporte de cierre."
                to mensaje-error
            perform detener-con-error
        end-if
    end-if.

detener-con-error.
    display "ERROR: " function trim(mensaje-error)
    move 1 to error-ejecucion.
