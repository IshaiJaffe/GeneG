		function validate(){
			var emptyEmail="Please enter an email address";
			var formatEmail="Please enter a valid email address";
			var emptyPassword="Please enter a password";
			var formatPassword="Please enter 6-10 letters or digits";
			var passwordMatch="Passwords do not match";
			var emptyBrowse="Please upload a vcf file";
			var passwordRegex=/^[a-zA-Z0-9]{6,10}$/;
			var emailRegex=/^([0-9a-zA-Z]([-.\w]*[0-9a-zA-Z])*@(([0-9a-zA-Z])+([-\w]*[0-9a-zA-Z])*\.)+[a-zA-Z]{2,9})$/;
			$(".error").html("&nbsp;");
			$(".error").css("visibility","hidden");
			var errflag=false;
			var email;
			var password;
			var confPass;
			//check which form is active
			if($(".register.active").length){
				email=$("#registerEmail");
				password=$("#registerPassword");
				confPass=$("#confPass");
				var browse=$("#fakeFile");
				if(browse.val()==""){
					$("#browseErr").html(emptyBrowse);
					errflag=true;
				}
			} 
			else if($(".login.active").length){
				email=$("#loginEmail");
				password=$("#loginPassword");
				confPass=null;
			} 
			else if($(".forgot_password.active").length){
				email=$("#forgotEmail");
				password=null;
				confPass=null;
			} 

			if(email.val()==""){
					var error=email.next();
					error.html(emptyEmail);
					errflag=true;
			}
			else if (!emailRegex.test(email.val()))
			{
					var error=email.next();
					error.html(formatEmail);
					errflag=true;
			}
			if(password!=null){
				if(password.val()==""){
						var error=password.next();
						error.html(emptyPassword);
						errflag=true;
				}
				else if (!passwordRegex.test(password.val()))
				{
						var error=password.next();
						error.html(formatPassword);
						errflag=true;
				}
				else if(confPass!=null && confPass.val()!=password.val()){
					var error=confPass.next();
					error.html(passwordMatch);
					errflag=true;
				}
			}

			if(errflag){
				$(".error").css("visibility","visible");
				return false;
			}
			return true;

		}
		
		
		$(function() {
					//the form wrapper (includes all forms)
				var $form_wrapper	= $('#form_wrapper'),
					//the current form is the one with class active
					$currentForm	= $form_wrapper.children('form.active'),
					//the change form links
					$linkform		= $form_wrapper.find('.linkform');
						
				//get width and height of each form and store them for later						
				$form_wrapper.children('form').each(function(i){
					var $theForm	= $(this);
					//solve the inline display none problem when using fadeIn fadeOut
					if(!$theForm.hasClass('active'))
						$theForm.hide();
					$theForm.data({
						width	: $theForm.width(),
						height	: $theForm.height()
					});
				});
				
				//set width and height of wrapper (same of current form)
				setWrapperWidth();
				
				/*
				clicking a link (change form event) in the form
				makes the current form hide.
				The wrapper animates its width and height to the 
				width and height of the new current form.
				After the animation, the new form is shown
				*/
				$linkform.bind('click',function(e){
					var $link	= $(this);
					var target	= $link.attr('rel');
					$currentForm.fadeOut(400,function(){
						//remove class active from current form
						$currentForm.removeClass('active');
						//new current form
						$currentForm= $form_wrapper.children('form.'+target);
						//animate the wrapper
						$form_wrapper.stop()
									 .animate({
										width	: $currentForm.data('width') + 'px',
										height	: $currentForm.data('height') + 'px'
									 },500,function(){
										//new form gets class active
										$currentForm.addClass('active');
										//show the new form
										$currentForm.fadeIn(400);
									 });
					});
					e.preventDefault();
				});
				
				function setWrapperWidth(){
					$form_wrapper.css({
						width	: $currentForm.data('width') + 'px',
						height	: $currentForm.data('height') + 'px'
					});
				}
				
				/*
				for the demo we disabled the submit buttons
				if you submit the form, you need to check the 
				which form was submited, and give the class active 
				to the form you want to show
				*/
				$form_wrapper.find('input[type="submit"]')
							 .click(function(e){
								e.preventDefault();
							 });	
			});

			$(document).ready(function(){
					var realFile=$("#realFile")[0];
					realFile.onchange = realFile.onmouseout = function () {
						$("#fakeFile").val(this.value);
						}
	
			});
