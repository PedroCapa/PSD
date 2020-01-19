package main.java.terminal;

import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import java.time.LocalDateTime;
import java.time.ZonedDateTime;
import java.time.ZoneId;
import java.util.Random;

public class ZeroMQ{

    public static void main(String[] args) throws Exception{
        ZContext zcont = new ZContext();
        ZMQ.Context context = ZMQ.context(1);
        ZMQ.Socket socket = context.socket(ZMQ.REP);        //Este é usado para receber mensagens dos Subscritores
        ZMQ.Socket publisher = zcont.createSocket(ZMQ.PUB); //Este é usado para enviar mensagens para os subscitores  que subscrevem o topico
        socket.bind("tcp://*:5555");
        publisher.bind("tcp://*:6666");

        while (!Thread.currentThread().isInterrupted()) {
            //Receb dos subbscritores. Significa que eles criaram um produto
            byte[] b = socket.recv();
            socket.send(new String(b));
            String s = new String(b);
            String[] arrOfStr = s.split(",");
            System.out.println("ZeroMQ: Received " + s + "  and send");
            String channel = arrOfStr[1] + "," + arrOfStr[2];

            if(arrOfStr[0].equals("Fabricante")){
                //Falta converter o tempo da mensagem para o LocalDateTime
                AlertSubscriber as = new AlertSubscriber(LocalDateTime.now(), channel, publisher);
                Thread t = new Thread(as);
                t.start();
            }
            else{
                publisher.sendMore(arrOfStr[1] + "," + arrOfStr[2]);
                publisher.send("Offer");
            }
        }
        System.out.println("Acabei");
    }
}

class AlertSubscriber implements Runnable{
    //O tempo que vai acabar as ofertas da produção
    private LocalDateTime tempo;
    //Canal que ira ter que publicar as mensagens
    private String channel;
    //Vai comunicar com outros
    private ZMQ.Socket publisher;

    public AlertSubscriber(LocalDateTime ldt, String channel, ZMQ.Socket publisher){
        this.tempo = ldt;
        this.channel = channel;
        this.publisher = publisher;
    }

    public void run(){
        try{
            ZonedDateTime zdt = this.tempo.atZone(ZoneId.of("Europe/Lisbon"));
            long falta = zdt.toInstant().toEpochMilli() - System.currentTimeMillis();
            System.out.println("AlertSubscriber: Daqui a uns segundos vou enviar para todos os subscritores");
            Thread.sleep(20000);
            //Enviar qual o topico que vai escrever
            publisher.sendMore(this.channel);
            publisher.send("Over");
            //Enviar qual o produto que acabou de ser vendido
        }
        catch(Exception e){
            System.out.println("AlertSubscriber:Deu barraca " + e.getMessage());
        }
        System.out.println("AlertSubscriber: Acabei de enviar para toda a gente");
    }
}