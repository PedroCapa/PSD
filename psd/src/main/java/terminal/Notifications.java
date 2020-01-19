package main.java.terminal;

import java.io.InputStream;
import java.io.IOException;
import java.net.Socket;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import main.proto.Protos.Notification;
import main.proto.Protos.FabSyn;
import main.proto.Protos.ImpSyn;

public class Notifications implements Runnable{

	private ZContext zcont = new ZContext();
	private ZMQ.Socket subscriber;
	private SendMessage sm;
	private boolean importador;
	private String username;

	public Notifications(SendMessage sm, boolean importador, String username){
    	this.subscriber = zcont.createSocket(SocketType.SUB);
    	this.sm = sm;
    	this.importador = importador;
    	this.username = username;
	}

	public void run(){
        try{

           System.out.println("Notification: Ready to receive notifications");
            this.subscriber.connect("tcp://localhost:6666");

            while(!Thread.currentThread().isInterrupted()){
            	String channel = subscriber.recvStr();
            	String[] arrOfStr = channel.split(",");
                String cont = subscriber.recvStr();
            	System.out.println("Recebi notificação do canal: " + channel + " com conteúdo" + cont);

            	if(importador && cont.equals("Over")){
                    Thread.sleep(500);
    				ImpSyn impsyn = ImpSyn.newBuilder().
                                           setType(ImpSyn.OpType.FINISH).
                                           build();
    				Notification notification = Notification.newBuilder().
    														setFabricante(arrOfStr[0]).
    														setProduto(arrOfStr[1]).
    														setUsername(this.username).
    														build();
                    byte[] syn = impsyn.toByteArray();
            		byte[] bytes = notification.toByteArray();
            		sm.sendServer(syn, bytes);
            	}
            	else if(!importador && cont.equals("Over")){
    				FabSyn fabsyn = FabSyn.newBuilder().
                                           setType(FabSyn.OpType.OVER).
                                           build();
            		Notification notification = Notification.newBuilder().
    														setFabricante(arrOfStr[0]).
    														setProduto(arrOfStr[1]).
    														setUsername("PSD").
    														build();
            		byte[] bytes = notification.toByteArray();
                    byte[] syn = fabsyn.toByteArray();
            		sm.sendServer(syn, bytes);
            	}
                else{
                   System.out.println("Notification: Fizeram uma oferta no Produtor: " + arrOfStr[0] + " Produto: " + arrOfStr[1]);
                }
            }
        }
        catch(Exception e){
           System.out.println("Notification: Exceção nas notificações");
            e.printStackTrace();
        }
    }

    public void subscribe(String prod){
        this.subscriber.subscribe(prod);
    }
}