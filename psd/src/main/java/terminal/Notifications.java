package main.java.terminal;

import java.io.InputStream;
import java.io.IOException;
import java.net.Socket;

import org.zeromq.SocketType;
import org.zeromq.ZMQ;
import org.zeromq.ZContext;

import main.proto.Protos.Notification;

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
        
        System.out.println("Ready to receive notifications");
        this.subscriber.connect("tcp://localhost:6666");

        while(!Thread.currentThread().isInterrupted()){
        	String channel = subscriber.recvStr();
        	System.out.println("Acabou o tempo do produto " + channel);
        	String[] arrOfStr = channel.split(",");
        	if(importador){
				//-----Criar o Syn
				Notification notification = Notification.newBuilder().
														setFabricante(arrOfStr[0]).
														setProduto(arrOfStr[1]).
														setUsername(this.username).
														build();
        		byte[] bytes = notification.toByteArray();
        		sm.sendServer(bytes);//----Enviar duas mensagens
        	}
        	else{
				//-----Criar o Syn
        		Notification notification = Notification.newBuilder().
														setFabricante(arrOfStr[0]).
														setProduto(arrOfStr[1]).
														setUsername("").
														build();
        		byte[] bytes = notification.toByteArray();
        		sm.sendServer(bytes);//----Enviar duas mensagens
        	}
        }
    }

    public void subscribe(String prod){
        this.subscriber.subscribe(prod);
    }
}